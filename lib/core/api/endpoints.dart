class Endpoints {
  static const String baseUrl = 'https://oilgid.addy.kz/api';

  // app
  static const appConfig = '/app/config';
  static const appInit = '/initApp';

  // cars
  static const carMarks = '/cars/marks';
  static const carModels = '/cars/marks/{mark_id}/models';
  static const carGenerations =
      '/cars/marks/{mark_id}/models/{model_id}/generations';
  static const carConfigurations =
      '/cars/marks/{mark_id}/models/{model_id}/generations/{generation_id}/configurations';

  // auth
  static const login = '/auth/login';

  // user
  static const profile = '/user/profile';
}
