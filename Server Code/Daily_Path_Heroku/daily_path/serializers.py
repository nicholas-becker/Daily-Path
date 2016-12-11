from rest_framework import serializers
from daily_path.models import PathPoint, UserPath

class PathPointSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = PathPoint
        fields = ('user_path', 'x', 'y')

class UserPathSerializer(serializers.ModelSerializer):
    points = PathPointSerializer(many=True)
    
    class Meta:
        model = UserPath
        fields = ('id', 'path_name', 'path_dist', 'created', 'points')
        
    
    def create(self, validated_data):
        """
        Create and return a new `UserPath` instance, given the validated data.
        """
        points_data = validated_data.pop('points')
        userpath = UserPath.objects.create(**validated_data)
        for point_data in points_data:
            PathPoint.objects.create(user_path=userpath, **point_data)
            
        return userpath