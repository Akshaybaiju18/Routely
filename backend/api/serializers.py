from rest_framework import serializers
from transport.models import Stop, Route, RouteStop, Journey

class StopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Stop
        fields = '__all__'

class RouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Route
        fields = '__all__'

class RouteStopSerializer(serializers.ModelSerializer):
    stop = StopSerializer(read_only=True)
    class Meta:
        model = RouteStop
        fields = ['id', 'stop', 'sequence_number']

class JourneySerializer(serializers.ModelSerializer):
    class Meta:
        model = Journey
        fields = '__all__'
