import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action, computed } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class extends Controller {
  @service dialog;
  @service siteSettings;

  @tracked deviceId = null;
  @tracked mobileDevice = false;
  @tracked loading = false;
  @tracked refreshing = false;

  @computed
  get onboardingTopicLink() {
    return `/t/${this.siteSettings.kolide_onboarding_topic_id}`;
  }

  @action
  async setKolideDevice() {
    if (!this.mobileDevice && !this.deviceId) {
      this.dialog.alert({
        message: i18n("discourse_kolide.onboarding.device_empty"),
      });
      return;
    }

    this.loading = true;

    const options = {
      type: "POST",
      processData: false,
      contentType: false,
      data: new FormData(),
    };

    if (this.mobileDevice) {
      options.data.append("is_mobile", true);
    } else {
      options.data.append("device_id", this.deviceId);
    }

    ajax("/kolide/devices/current", options)
      .then(() => {
        window.location.reload();
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.loading = false;
      });
  }

  @action
  refreshDevices() {
    this.refreshing = true;

    ajax("/kolide/devices/refresh", { type: "PUT" })
      .then((devices) => {
        this.model = devices;
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.refreshing = false;
      });
  }
}
