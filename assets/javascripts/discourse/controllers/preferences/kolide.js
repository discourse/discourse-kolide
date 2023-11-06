import Controller from "@ember/controller";
import { action, computed } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";

export default class extends Controller {
  @service dialog;
  @service siteSettings;

  @tracked deviceId = null;
  @tracked loading = false;
  @tracked refreshing = false;

  @computed
  get onboardingTopicLink() {
    return `/t/${this.siteSettings.kolide_onboarding_topic_id}`;
  }

  @action
  async setKolideDevice() {
    if (!this.deviceId) {
      this.dialog.alert({ message: I18n.t("discourse_kolide.onboarding.device_empty") });
      return;
    }

    this.loading = true;

    const options = {
      type: "POST",
      processData: false,
      contentType: false,
      data: new FormData(),
    };

    options.data.append("device_id", this.deviceId);

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
