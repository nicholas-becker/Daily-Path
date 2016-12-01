from django.contrib import admin

from .models import UserPath, PathPoint

class UserPathAdmin(admin.ModelAdmin):
    fields = ['path_name', 'path_dist']
    
admin.site.register(UserPath, UserPathAdmin)

class PathPointAdmin(admin.ModelAdmin):
    fields = ['user_path', 'x', 'y']
    
admin.site.register(PathPoint, PathPointAdmin)