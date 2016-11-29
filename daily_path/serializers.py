from rest_framework import serializers
from daily_path.models import PathPoint, UserPath

class UserPathSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    path_name = serializers.CharField(required=True, allow_blank=False, max_length=100)
    
    def create(self, validated_data):
        """
        Create and return a new `UserPath` instance, given the validated data.
        """
        return UserPath.objects.create(**validated_data)
        
    def update(self, instance, validated_data):
        """
        Update and return an existing `UserPath` instance, given the validated data.
        """
        instance.path_name = validated_data.get('path_name', instance.path_name)
        instance.save()
        return instance