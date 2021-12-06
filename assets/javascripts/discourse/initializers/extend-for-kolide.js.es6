import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";

function initializeWithApi(api) {
  const currentUser = api.getCurrentUser();

  if (currentUser) {
    const site = api.container.lookup("site:main");

    if (site.non_onboarded_device) {
      api.addGlobalNotice(
        I18n.t("discourse_kolide.non_onboarded_device.notice", { link: "/t/" }),
        "non-onboarded-device"
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
