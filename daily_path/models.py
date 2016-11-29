from django.db import models

class UserPath(models.Model):
    path_name = models.CharField(max_length=100)
    created = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ('created',)

class PathPoint(models.Model):
    point_name = models.CharField(max_length=100)
    created = models.DateTimeField(auto_now_add=True)
    parent_path = models.ForeignKey(UserPath, on_delete=models.CASCADE)
    latitude = models.CharField(max_length=100, default='0°00\'00.0\"N')
    longitude = models.CharField(max_length=100, default='0°00\'00.0\"E')
    
    class Meta:
        ordering = ('created',)