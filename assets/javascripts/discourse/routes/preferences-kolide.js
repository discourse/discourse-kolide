import RestrictedUserRoute from "discourse/routes/restricted-user";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import cookie from "discourse/lib/cookie";

export default class PreferencesKolideRoute extends RestrictedUserRoute {
  model() {
    return ajax("/kolide/devices").catch(popupAjaxError);
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    const deviceId = cookie("kolide_device_id");

    if (deviceId) {
      controller.set("deviceId", parseInt(deviceId, 10));
    }
  }
}
