from django.http import HttpResponse, JsonResponse
from django.utils.six import BytesIO
from rest_framework.renderers import JSONRenderer
from rest_framework.parsers import JSONParser
from rest_framework.decorators import api_view
from daily_path.models import UserPath, PathPoint
from daily_path.serializers import UserPathSerializer, PathPointSerializer
import json

# def __init__(data, **kwargs):
#     content = JSONRenderer().render(data)
#     kwargs['content_type'] = 'application/json'
#     super(JSONResponse, self).__init__(content, **kwargs)
        
# @api_view(['GET'])
# def get_path(request, pk):
#     try:
#         userpath = UserPath.objects.get(pk=pk)
#     except UserPath.DoesNotExist:
#         return HttpResponse(status=404)
    
#     serializer = UserPathSerializer(userpath, many=True)
#     if request.method == 'GET':
#         return JsonResponse(serializer.data)

# @api_view(['GET'])
# def get_all_paths(request):
#     try:
#         userpaths = UserPath.objects.order_by('created')
#     except UserPath.DoesNotExist:
#         return HttpResponse(status=404)
#     serializer = UserPathSerializer(userpaths, many=True)
#     if request.method == 'GET':
#         return JsonResponse(serializer.data)

@api_view(['GET'])
def get_all_paths(request):
    try:
        userpaths = UserPath.objects.order_by('created')
    except UserPath.DoesNotExist:
        return HttpResponse(status=404)
    serializer = UserPathSerializer(userpaths, many=True)
    # content = JSONRenderer().render(serializer.data)
    # stream = BytesIO(content)
    # data = JSONParser().parse(stream)
    # serializer = UserPathSerializer(data = data, many=True)
    # if serializer.is_valid():
    return JsonResponse(serializer.data, safe=False)

@api_view(['POST'])
def create_path(request):
    # try:
    print (request.POST.objects.all())
    pathname = request.POST.get('path_name')
    print(pathname)
    pathdist = request.POST.get('path_dist')
    print(pathdist)
    
    userpath = UserPath(path_name=pathname, path_dist=pathdist)
    userpath.save()
    
    points = request.POST.get('points').split(',')
    
    i = 0
    while i < len(points):
        pathpoint = PathPoint(user_path=userpath, x=points[i], y=points[i+1])
        pathpoint.save()
        i = i + 2
    
    json_data = UserPathSerializer(userpath)
    if request.method == 'POST':
        return JsonResponse(json_data.data, safe=False)
    #     pathpoint = PathPoint(user_path=userpath, x=x, y=y)
    #     pathpoint.save()
    # except UserPath.DoesNotExist:
    #     return HttpResponse(status=404)
    # serializer = UserPathSerializer(userpath)
    # return JsonResponse(serializer.data)       

@api_view(['GET'])
def get_path(request, pk):
    try:
        userpath = UserPath.objects.get(pk=pk)
    except UserPath.DoesNotExist:
        return HttpResponse(status=404)
    serializer = UserPathSerializer(userpath)
    return JsonResponse(serializer.data)
    


# @csrf_exempt
# def path_detail(request, pk):
#     """
#     Retrieve or delete a user generated path.
#     """
#     try:
#         userpath = UserPath.objects.get(pk=pk)
#     except UserPath.DoesNotExist:
#         return HttpResponse(status=404)
        
#     if request.method == 'GET':
#         serializer = UserPathSerializer(userpath)
#         return JSONResponse(serializer.data)
        
        
#     elif request.method == 'DELETE':
#         userpath.delete()
#         return HttpResponse(status=204)