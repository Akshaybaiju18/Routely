from django.core.management.base import BaseCommand
from transport.models import Stop, Route, RouteStop

class Command(BaseCommand):
    help = "Seed the database with Kochi bus routes and stops"

    def handle(self, *args, **options):
        self.stdout.write("Clearing existing transport data...")
        RouteStop.objects.all().delete()
        Route.objects.all().delete()
        Stop.objects.all().delete()

        self.stdout.write("Creating stops...")
        stops_data = [
            {"name": "Infopark Kakkanad", "latitude": 9.9931, "longitude": 76.3575, "city": "Kochi", "landmark": "Infopark Campus"},
            {"name": "Kakkanad", "latitude": 10.0120, "longitude": 76.3510, "city": "Kochi", "landmark": "Collectorate"},
            {"name": "Edappally", "latitude": 10.0260, "longitude": 76.3080, "city": "Kochi", "landmark": "Lulu Mall"},
            {"name": "Kaloor", "latitude": 9.9880, "longitude": 76.3000, "city": "Kochi", "landmark": "Metro Station"},
            {"name": "Vyttila Hub", "latitude": 9.9690, "longitude": 76.3200, "city": "Kochi", "landmark": "Transit Hub"},
            {"name": "MG Road", "latitude": 9.9750, "longitude": 76.2800, "city": "Kochi", "landmark": "Shopping Street"},
            {"name": "Fort Kochi", "latitude": 9.9670, "longitude": 76.2430, "city": "Kochi", "landmark": "Beach & Chinese Fishing Nets"},
        ]

        stops = {}
        for stop_info in stops_data:
            stop = Stop.objects.create(**stop_info)
            stops[stop.name] = stop
            self.stdout.write(f"Created stop: {stop.name}")

        self.stdout.write("Creating routes...")
        routes_data = [
            {"board_name": "Route A (Infopark - Kaloor)", "operator": "KSRTC", "active": True},
            {"board_name": "Route B (Kaloor - Fort Kochi)", "operator": "Private", "active": True},
            {"board_name": "Route C (Kakkanad - MG Road)", "operator": "KSRTC", "active": True},
        ]

        routes = {}
        for route_info in routes_data:
            route = Route.objects.create(**route_info)
            routes[route.board_name] = route
            self.stdout.write(f"Created route: {route.board_name}")

        self.stdout.write("Connecting stops to routes...")
        
        # Route A: Infopark -> Kakkanad -> Edappally -> Kaloor
        route_a_stops = [
            ("Infopark Kakkanad", 1),
            ("Kakkanad", 2),
            ("Edappally", 3),
            ("Kaloor", 4),
        ]
        for stop_name, seq in route_a_stops:
            RouteStop.objects.create(
                route=routes["Route A (Infopark - Kaloor)"],
                stop=stops[stop_name],
                sequence_number=seq
            )

        # Route B: Kaloor -> MG Road -> Fort Kochi
        route_b_stops = [
            ("Kaloor", 1),
            ("MG Road", 2),
            ("Fort Kochi", 3),
        ]
        for stop_name, seq in route_b_stops:
            RouteStop.objects.create(
                route=routes["Route B (Kaloor - Fort Kochi)"],
                stop=stops[stop_name],
                sequence_number=seq
            )

        # Route C: Kakkanad -> Vyttila Hub -> MG Road
        route_c_stops = [
            ("Kakkanad", 1),
            ("Vyttila Hub", 2),
            ("MG Road", 3),
        ]
        for stop_name, seq in route_c_stops:
            RouteStop.objects.create(
                route=routes["Route C (Kakkanad - MG Road)"],
                stop=stops[stop_name],
                sequence_number=seq
            )

        self.stdout.write(self.style.SUCCESS("Database seeding completed successfully!"))
