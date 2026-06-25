from django.db import models

class Stop(models.Model):
    name = models.CharField(max_length=255)
    latitude = models.FloatField()
    longitude = models.FloatField()
    city = models.CharField(max_length=100)
    landmark = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.name} ({self.city})"

class Route(models.Model):
    board_name = models.CharField(max_length=255)
    operator = models.CharField(max_length=255)
    active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.board_name} ({self.operator})"

class RouteStop(models.Model):
    route = models.ForeignKey(Route, on_delete=models.CASCADE, related_name='route_stops')
    stop = models.ForeignKey(Stop, on_delete=models.CASCADE, related_name='route_stops')
    sequence_number = models.PositiveIntegerField()

    class Meta:
        ordering = ['sequence_number']
        unique_together = ('route', 'sequence_number')

    def __str__(self):
        return f"{self.route} - Stop {self.stop.name} (#{self.sequence_number})"

class Journey(models.Model):
    source_name = models.CharField(max_length=255)
    destination_name = models.CharField(max_length=255)
    source_lat = models.FloatField()
    source_lng = models.FloatField()
    dest_lat = models.FloatField()
    dest_lng = models.FloatField()
    response_data = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Journey {self.id}: {self.source_name} -> {self.destination_name}"
