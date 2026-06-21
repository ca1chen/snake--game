export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_mobile.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';
