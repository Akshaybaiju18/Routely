from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from transport.models import Stop, Route, RouteStop, Journey

class APITests(APITestCase):
    def setUp(self):
        # Create Stops
        self.stop_a = Stop.objects.create(name="Infopark Kakkanad", latitude=9.9931, longitude=76.3575, city="Kochi")
        self.stop_b = Stop.objects.create(name="Kaloor", latitude=9.9880, longitude=76.3000, city="Kochi")

        # Create Route
        self.route = Route.objects.create(board_name="Route A", operator="KSRTC")

        # RouteStop
        RouteStop.objects.create(route=self.route, stop=self.stop_a, sequence_number=1)
        RouteStop.objects.create(route=self.route, stop=self.stop_b, sequence_number=2)

    def test_list_stops(self):
        url = reverse('stop-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

    def test_nearby_stops(self):
        url = reverse('stop-nearby')
        response = self.client.get(url, {'lat': '9.9931', 'lng': '76.3575', 'radius': '1.0'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) > 0)
        self.assertEqual(response.data[0]['name'], "Infopark Kakkanad")

    def test_search_stops(self):
        url = reverse('api-search')
        response = self.client.post(url, {'query': 'Kakkanad'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], "Infopark Kakkanad")

    def test_create_journey(self):
        url = reverse('api-journey')
        data = {
            'source_lat': 9.9931,
            'source_lng': 76.3575,
            'dest_lat': 9.9880,
            'dest_lng': 76.3000
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['source_name'], "Infopark Kakkanad")
        self.assertEqual(response.data['destination_name'], "Kaloor")
        self.assertTrue(len(response.data['response_data']['options']) > 0)

        # Get details of created journey
        journey_id = response.data['id']
        detail_url = reverse('api-journey-detail', kwargs={'pk': journey_id})
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
