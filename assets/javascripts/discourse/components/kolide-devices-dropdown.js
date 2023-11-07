import discourseComputed from "discourse-common/utils/decorators";
import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";

export default DropdownSelectBoxComponent.extend({
  devices: [],
  classNames: ["kolide-devices-dropdown"],
  pluginApiIdentifiers: ["kolide-devices-dropdown"],
  selectKitOptions: {
    icon: null,
    showCaret: true,
    none: "discourse_kolide.onboarding.select_device",
    showFullTitle: true,
  },

  @discourseComputed("devices")
  content(devices) {
    return devices.map((device) => {
      return {
        id: device.id,
        title: device.name,
        description: device.hardware_model,
        icon: device.is_orphan ? "question" : "user",
      };
    });
  },
});
