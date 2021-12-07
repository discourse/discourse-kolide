import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";

function initializeWithApi(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser) {
    const site = api.container.lookup("site:main");
    const siteSettings = api.container.lookup("site-settings:main");
    const onboarding_topic_id = siteSettings.kolide_onboarding_topic_id;

    if (site.non_onboarded_device && onboarding_topic_id > -1) {
      api.addGlobalNotice(
        I18n.t("discourse_kolide.non_onboarded_device.notice", { link: `/t/${onboarding_topic_id}` }),
        "non-onboarded-device",
        {
          dismissable: true,
          persistentDismiss: true,
          dismissDuration: moment.duration(1, "day")
        }
      );
    }
  }
}

export default {
  name: "extend-for-kolide",
  initialize() {
    withPluginApi("0.1", initializeWithApi);
  },
};
