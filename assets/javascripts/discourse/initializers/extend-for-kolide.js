import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import cookie from "discourse/lib/cookie";

function initializeWithApi(api) {
  const currentUser = api.getCurrentUser();

  function attachButtons(cooked) {
    const assignButtons = cooked.querySelectorAll("a.kolide-assign") || [];
    const recheckButtons = cooked.querySelectorAll("a.kolide-recheck") || [];

    assignButtons.forEach((button) => {
      button.addEventListener("click", assignUser, false);
    });

    recheckButtons.forEach((button) => {
      button.addEventListener("click", recheckIssue, false);
    });
  }

  function assignUser() {
    const userId = this.dataset.user;
    const deviceId = this.dataset.device;

    ajax(`/kolide/devices/${deviceId}/assign.json`, {
      type: "PUT",
      data: { user_id: userId },
    })
      .then(() => {
        const dialog = api.container.lookup("service:dialog");
        dialog.alert(I18n.t("discourse_kolide.device_assigned"));
      })
      .catch(popupAjaxError);

    return false;
  }

  function recheckIssue() {
    const issueId = this.dataset.issue;

    ajax(`/kolide/issues/${issueId}/recheck.json`, { type: "POST" })
      .then(() => {
        const dialog = api.container.lookup("service:dialog");
        dialog.alert(I18n.t("discourse_kolide.issue_recheck_initiated"));
      })
      .catch(popupAjaxError);

    return false;
  }

  if (currentUser) {
    api.decorateCookedElement(attachButtons, {
      onlyStream: false,
      id: "discouse-kolide-buttons",
    });

    if (cookie("kolide_non_onboarded")) {
      const site = api.container.lookup("site:main");
      const siteSettings = api.container.lookup("site-settings:main");
      const onboarding_topic_id = siteSettings.kolide_onboarding_topic_id;

      if (onboarding_topic_id > 0 && !site.mobileView) {
        api.addGlobalNotice(
          I18n.t("discourse_kolide.non_onboarded_device.notice", {
            link: `/t/${onboarding_topic_id}`,
          }),
          "non-onboarded-device",
          {
            dismissable: true,
            persistentDismiss: true,
            dismissDuration: moment.duration(1, "week"),
          }
        );
      }
    }
  }
}

export default {
  name: "extend-for-kolide",
  initialize() {
    withPluginApi("0.1", initializeWithApi);
  },
};
