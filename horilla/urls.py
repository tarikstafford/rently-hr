"""horilla URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.conf.urls.static import static
from django.contrib import admin
from django.db import connection
from django.http import JsonResponse, HttpResponse
from django.urls import include, path, re_path
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.cache import never_cache
import logging

import notifications.urls

from . import settings

logger = logging.getLogger(__name__)


@csrf_exempt
@never_cache
@require_http_methods(["GET"])
def health_check(request):
    """
    Simple health check endpoint that returns 200 OK.
    This endpoint is exempt from CSRF and SSL redirect.
    """
    logger.info(f"Health check request received from {request.META.get('REMOTE_ADDR')}")
    logger.info(f"Request scheme: {request.scheme}")
    logger.info(f"Request headers: {request.headers}")
    logger.info(f"Request path: {request.path}")
    logger.info(f"Request method: {request.method}")
    
    return HttpResponse("OK", status=200, content_type="text/plain")


urlpatterns = [
    path("admin/", admin.site.urls),
    path("accounts/", include("django.contrib.auth.urls")),
    path("accounts/", include("django.contrib.auth.urls")),
    path("", include("base.urls")),
    path("", include("horilla_automations.urls")),
    path("", include("horilla_views.urls")),
    path("employee/", include("employee.urls")),
    path("horilla-widget/", include("horilla_widgets.urls")),
    re_path(
        "^inbox/notifications/", include(notifications.urls, namespace="notifications")
    ),
    path("i18n/", include("django.conf.urls.i18n")),
    path("health/", health_check, name='health_check'),
]

# if settings.DEBUG:
#     urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
