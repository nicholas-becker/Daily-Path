from django.db import models

class UserPath(models.Model):
    path_name = models.CharField(max_length=100, default='')
    created = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.created + ': ' + self.path_name
    
    class Meta:
        ordering = ('created',)

class PathPoint(models.Model):
    point_name = models.CharField(max_length=100, default='')
    created = models.DateTimeField(auto_now_add=True)
    parent_path = models.ForeignKey(UserPath, on_delete=models.CASCADE)
    latitude = models.CharField(max_length=100, default='0degs0mins0secsN')
    longitude = models.CharField(max_length=100, default='0degs0mins0secsW')
    
    def __str__(self):
        return self.created + ': ' + self.point_name + ' (' + self.latitude + ', ' + self.longitude + ')'
    
    class Meta:
        ordering = ('created',)