from django.test import TestCase
from transport.models import Stop, Route, RouteStop
from routing.engine import find_journeys, haversine_distance, get_nearby_stops, calculate_fare

class RoutingEngineTests(TestCase):
    def setUp(self):
        # Create Stops
        self.stop_a = Stop.objects.create(name="Stop A", latitude=10.0, longitude=76.0, city="Test City")
        self.stop_b = Stop.objects.create(name="Stop B", latitude=10.01, longitude=76.01, city="Test City")
        self.stop_c = Stop.objects.create(name="Stop C", latitude=10.02, longitude=76.02, city="Test City")
        self.stop_d = Stop.objects.create(name="Stop D", latitude=10.03, longitude=76.03, city="Test City")

        # Create Routes
        self.route_1 = Route.objects.create(board_name="Route 1", operator="Op 1")
        self.route_2 = Route.objects.create(board_name="Route 2", operator="Op 2")

        # Route 1: Stop A -> Stop B -> Stop C
        RouteStop.objects.create(route=self.route_1, stop=self.stop_a, sequence_number=1)
        RouteStop.objects.create(route=self.route_1, stop=self.stop_b, sequence_number=2)
        RouteStop.objects.create(route=self.route_1, stop=self.stop_c, sequence_number=3)

        # Route 2: Stop C -> Stop D
        RouteStop.objects.create(route=self.route_2, stop=self.stop_c, sequence_number=1)
        RouteStop.objects.create(route=self.route_2, stop=self.stop_d, sequence_number=2)

    def test_haversine_distance(self):
        # Distance between (10.0, 76.0) and (10.0, 76.0) should be 0
        dist = haversine_distance(10.0, 76.0, 10.0, 76.0)
        self.assertEqual(dist, 0.0)

    def test_calculate_fare(self):
        self.assertEqual(calculate_fare(2), 10.0)
        self.assertEqual(calculate_fare(3), 10.0)
        self.assertEqual(calculate_fare(4), 12.0)
        self.assertEqual(calculate_fare(5), 14.0)

    def test_get_nearby_stops(self):
        # Close to Stop A
        nearby = get_nearby_stops(10.0, 76.0, radius_km=1.0)
        self.assertEqual(len(nearby), 1)
        self.assertEqual(nearby[0][0].name, "Stop A")

    def test_find_direct_journey(self):
        # From Stop A to Stop C (Direct on Route 1)
        journeys = find_journeys(10.0, 76.0, 10.02, 76.02, radius_km=1.0)
        self.assertTrue(len(journeys) > 0)
        
        direct_journey = journeys[0]
        self.assertEqual(direct_journey["type"], "direct")
        self.assertEqual(direct_journey["bus_duration_mins"], 6)  # 2 stops * 3 mins
        self.assertEqual(direct_journey["total_fare"], 10.0)      # 2 stops <= 3

    def test_find_transfer_journey(self):
        # From Stop A to Stop D (Transfer at Stop C: Route 1 -> Route 2)
        journeys = find_journeys(10.0, 76.0, 10.03, 76.03, radius_km=1.0)
        self.assertTrue(len(journeys) > 0)
        
        # Filter for transfer journeys
        transfer_journeys = [j for j in journeys if j["type"] == "transfer"]
        self.assertTrue(len(transfer_journeys) > 0)
        
        j = transfer_journeys[0]
        self.assertEqual(j["bus_duration_mins"], 9)  # (2 stops on Route 1 + 1 stop on Route 2) * 3 mins
        self.assertEqual(j["total_fare"], 20.0)       # 10.0 for Route 1 (2 stops) + 10.0 for Route 2 (1 stop)
