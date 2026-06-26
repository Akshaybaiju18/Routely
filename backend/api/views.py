from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from transport.models import Stop, Route, Journey
from api.serializers import StopSerializer, RouteSerializer, JourneySerializer
from routing.engine import find_journeys, get_nearby_stops

class StopViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Stop.objects.all()
    serializer_class = StopSerializer

    @action(detail=False, methods=['get'], url_path='nearby')
    def nearby(self, request):
        lat_str = request.query_params.get('lat')
        lng_str = request.query_params.get('lng')
        radius_str = request.query_params.get('radius', '1.5')

        if not lat_str or not lng_str:
            return Response(
                {"error": "Query parameters 'lat' and 'lng' are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            lat = float(lat_str)
            lng = float(lng_str)
            radius = float(radius_str)
        except ValueError:
            return Response(
                {"error": "Invalid latitude, longitude, or radius values."},
                status=status.HTTP_400_BAD_REQUEST
            )

        nearby_stops = get_nearby_stops(lat, lng, radius)
        data = []
        for stop, dist in nearby_stops:
            serialized = self.get_serializer(stop).data
            serialized['distance_km'] = round(dist, 2)
            data.append(serialized)

        return Response(data)

class RouteViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Route.objects.all()
    serializer_class = RouteSerializer

class SearchView(APIView):
    def post(self, request):
        query = request.data.get('query', '').strip()
        if not query:
            return Response(
                {"error": "Request body field 'query' is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Search stops by name, city, or landmark
        stops = Stop.objects.filter(
            Q(name__icontains=query) |
            Q(city__icontains=query) |
            Q(landmark__icontains=query)
        )
        serializer = StopSerializer(stops, many=True)
        return Response(serializer.data)

class JourneyView(APIView):
    def post(self, request):
        source_lat = request.data.get('source_lat')
        source_lng = request.data.get('source_lng')
        dest_lat = request.data.get('dest_lat')
        dest_lng = request.data.get('dest_lng')

        if any(v is None for v in [source_lat, source_lng, dest_lat, dest_lng]):
            return Response(
                {"error": "Fields 'source_lat', 'source_lng', 'dest_lat', and 'dest_lng' are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            s_lat = float(source_lat)
            s_lng = float(source_lng)
            d_lat = float(dest_lat)
            d_lng = float(dest_lng)
        except ValueError:
            return Response(
                {"error": "Invalid coordinate values."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Calculate journeys
        options = find_journeys(s_lat, s_lng, d_lat, d_lng)

        # Infer names from the closest stops
        s_stops = get_nearby_stops(s_lat, s_lng, radius_km=5.0)
        d_stops = get_nearby_stops(d_lat, d_lng, radius_km=5.0)

        source_name = s_stops[0][0].name if s_stops else "Source Location"
        dest_name = d_stops[0][0].name if d_stops else "Destination Location"

        # Save to database
        journey = Journey.objects.create(
            source_name=source_name,
            destination_name=dest_name,
            source_lat=s_lat,
            source_lng=s_lng,
            dest_lat=d_lat,
            dest_lng=d_lng,
            response_data={"options": options}
        )

        serializer = JourneySerializer(journey)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class JourneyDetailView(APIView):
    def get(self, request, pk):
        try:
            journey = Journey.objects.get(pk=pk)
        except Journey.DoesNotExist:
            return Response(
                {"error": "Journey not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = JourneySerializer(journey)
        return Response(serializer.data)
