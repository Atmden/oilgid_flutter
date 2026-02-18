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
  static const carModifications =
      '/cars/marks/{mark_id}/models/{model_id}/generations/{generation_id}/configurations/{configuration_id}/modifications';

  // auth
  static const login = '/auth/login';
  static const verifySendCode = '/verify/sendCode';
  static const verifyCode = '/verify/verifyCode';
  static const register = '/auth/register';

  // user
  static const profile = '/user/profile';

  // oils
  static const oilsByModification =
      '/oils/by-modification/{modification_id}';

  // oil shops
  static const oilShop = '/oils/{oil_id}/shops';

  // oil shops markers
  static const oilShopsMarkers = '/oils/{oil_id}/markers';

  // shop products
  static const shopProducts = '/shops/{shop_id}/products';

}
