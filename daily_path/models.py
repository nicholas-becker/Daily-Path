from django.db import models

class UserPath(models.Model):
    path_name = models.CharField(max_length=100)
    path_dist = models.FloatField()
    created = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['id']
        
    def __unicode__(self):
        return self.path_name

class PathPoint(models.Model):
    user_path = models.ForeignKey(UserPath, related_name='points', on_delete=models.CASCADE, null=True)
    x = models.FloatField()
    y = models.FloatField()
    
    class Meta:
        unique_together = ('user_path', 'id')
        ordering = ['id']