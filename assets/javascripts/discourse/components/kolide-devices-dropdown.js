import { classNames } from "@ember-decorators/component";
import discourseComputed from "discourse-common/utils/decorators";
import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";
import {
  pluginApiIdentifiers,
  selectKitOptions,
} from "select-kit/components/select-kit";

@pluginApiIdentifiers("kolide-devices-dropdown")
@selectKitOptions({
  icon: null,
  showCaret: true,
  none: "discourse_kolide.onboarding.select_device",
  showFullTitle: true,
})
@classNames("kolide-devices-dropdown")
export default class KolideDevicesDropdown extends DropdownSelectBoxComponent {
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
  }
}
