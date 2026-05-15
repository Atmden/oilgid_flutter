class Endpoints {
  static const String baseUrl = 'https://oilgid.kz/api';

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
  static const authCheckUserByPhone = '/auth/check-user-by-phone';
  static const authResetPassword = '/auth/reset-password';
  static const verifySendCode = '/verify/sendCode';
  static const verifyCode = '/verify/verifyCode';
  static const register = '/auth/register';
  static const deleteAccount = '/auth/account';

  // user
  static const profile = '/user/profile';

  // oils
  static const oilsByModification = '/oils/by-modification/{modification_id}';
  static const oilsCatalog = '/oils/catalog';
  static const oilsCatalogFacets = '/oils/catalog/facets';
  static const oilsCatalogFiltersBrands = '/oils/catalog/filters/brands';
  static const oilsCatalogFiltersViscosities =
      '/oils/catalog/filters/viscosities';

  // oil details
  static const oilDetails = '/oils/{oil_id}';

  // oil shops
  static const oilShop = '/oils/{oil_id}/shops';

  // oil shops markers
  static const oilShopsMarkers = '/oils/{oil_id}/markers';

  // shop products
  static const shopProducts = '/shops/{shop_id}/products';

  // shop details
  static const shopDetails = '/shops/{shop_id}';

  // shops catalog
  static const shopCatalog = '/shops/catalog';

  // add car request
  static const addCarRequest = '/add_car_from_request';

  // garage
  static const garageCars = '/garage/cars';
  static const garageCar = '/garage/cars/{id}';
  static const garageServiceRecords = '/garage/service-records';
  static const garageServiceRecord = '/garage/service-records/{id}';
  static const garageServiceRecordMedia = '/garage/service-records/{id}/media';
  static const garageServiceRecordMediaDelete =
      '/garage/service-records/{id}/media/{mediaId}';

  // subscription
  static const subscriptionPlans = '/subscription/plans';
  static const subscriptionStatus = '/subscription/status';
  static const subscriptionValidatePurchase = '/subscription/validate-purchase';
  static const subscriptionRestore = '/subscription/restore';
}
