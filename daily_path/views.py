from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.renderers import JSONRenderer
from rest_framework.parsers import JSONParser
from daily_path.models import UserPath, PathPoint
from daily_path.serializers import UserPathSerializer, PathPointSerializer

class JSONResponse(HttpResponse):
    """
    An HttpResponse that renders its content into JSON.
    """
    def __init__(self, data, **kwargs):
        content = JSONRenderer().render(data)
        kwargs['content_type'] = 'application/json'
        super(JSONResponse, self).__init__(content, **kwargs)
        
    @csrf_exempt
    def path_list(self, request):
        """
        List all paths requested or create new paths.
        """
        if request.method == 'GET':
            userpaths = UserPath.objects.all()
            serializer = UserPathSerializer(userpaths, many=True)
            return JSONResponse(serializer.data)
            
        elif request.method == 'POST':
            data = JSONParser().parse(request)
            serializer = UserPathSerializer(data=data)
            if serializer.is_valid():
                serializer.save()
                return JSONResponse(serializer.data, status=201)
            return JSONResponse(serializer.errors, status=400)
    
    @csrf_exempt
    def path_detail(self, request, pk):
        """
        Retrieve or delete a user generated path.
        """
        try:
            userpath = UserPath.objects.get(pk=pk)
        except UserPath.DoesNotExist:
            return HttpResponse(status=404)
            
        if request.method == 'GET':
            serializer = UserPathSerializer(userpath)
            return JSONResponse(serializer.data)
            
            
        elif request.method == 'DELETE':
            userpath.delete()
            return HttpResponse(status=204)