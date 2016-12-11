from django.http import HttpResponse, JsonResponse
from django.utils.six import BytesIO
from rest_framework.renderers import JSONRenderer
from rest_framework.parsers import JSONParser
from rest_framework.decorators import api_view
from daily_path.models import UserPath, PathPoint
from daily_path.serializers import UserPathSerializer, PathPointSerializer
import json


@api_view(['GET'])
def get_all_paths(request):
    try:
        userpaths = UserPath.objects.order_by('created')
    except UserPath.DoesNotExist:
        return HttpResponse(status=404)
    serializer = UserPathSerializer(userpaths, many=True)

    return JsonResponse(serializer.data, safe=False)

@api_view(['POST'])
def create_path(request):
    # try:
    pathname = request.GET.get("path_name", "")
    print(pathname)
    pathdist = request.GET.get("path_dist", "")
    print(pathdist)
    
    userpath = UserPath(path_name=pathname, path_dist=pathdist)
    userpath.save()
    
    points = request.GET.get("points", "").split(',')
    
    i = 0
    while i < len(points):
        pathpoint = PathPoint(user_path=userpath, x=points[i], y=points[i+1])
        pathpoint.save()
        i = i + 2
    
    json_data = UserPathSerializer(userpath)
    if request.method == 'POST':
        return JsonResponse(json_data.data, safe=False)

@api_view(['DELETE'])
def delete_path(request, pk):
    instance = UserPath.objects.get(pk=pk)
    instance.delete()
    return HttpResponse("Path Deleted: " + pk)

@api_view(['GET'])
def get_path(request, pk):
    try:
        userpath = UserPath.objects.get(pk=pk)
    except UserPath.DoesNotExist:
        return HttpResponse(status=404)
    serializer = UserPathSerializer(userpath)
    return JsonResponse(serializer.data)
    