import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function initializeWithApi(api) {
  const currentUser = api.getCurrentUser();

  function attachAssignButton(cooked, helper) {
    const buttons = cooked.querySelectorAll("a.kolide-assign") || [];

    buttons.forEach((button) => {
      button.addEventListener("click", assignUser, false);
    });
  }

  function assignUser() {
    const userId = this.dataset.user;
    const deviceId = this.dataset.device;

    ajax(`/kolide/devices/${deviceId}/assign`, {
      type: "POST",
      data: { user_id: userId },
    })
      .then((_) => {
        bootbox.alert("Success");
      })
      .catch(popupAjaxError);

    return false;
  }

  if (currentUser) {
    const site = api.container.lookup("site:main");
    const siteSettings = api.container.lookup("site-settings:main");
    const onboarding_topic_id = siteSettings.kolide_onboarding_topic_id;

    if (site.non_onboarded_device && onboarding_topic_id > 0) {
      api.addGlobalNotice(
        I18n.t("discourse_kolide.non_onboarded_device.notice", {
          link: `/t/${onboarding_topic_id}`,
        }),
        "non-onboarded-device",
        {
          dismissable: true,
          persistentDismiss: true,
          dismissDuration: moment.duration(1, "day"),
        }
      );
    }

    api.decorateCookedElement(attachAssignButton, {
      onlyStream: false,
      id: "discouse-kolide-assign-button",
    });
  }
}

export default {
  name: "extend-for-kolide",
  initialize() {
    withPluginApi("0.1", initializeWithApi);
  },
};
