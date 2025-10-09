import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import { htmlSafe } from "@ember/template";
import RouteTemplate from "ember-route-template";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import bodyClass from "discourse/helpers/body-class";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import KolideDevicesDropdown from "../../components/kolide-devices-dropdown";

export default RouteTemplate(
  <template>
    {{bodyClass "user-preferences-page"}}

    <section class="user-content user-preferences solo-preference kolide">
      <ConditionalLoadingSpinner @condition={{@controller.loading}}>
        <div class="control-group">
          <label class="control-label">
            {{i18n "discourse_kolide.onboarding.title"}}
          </label>

          <div class="controls">
            <div class="inline-form">
              <KolideDevicesDropdown
                @devices={{@controller.model}}
                @value={{@controller.deviceId}}
                @onSelect={{fn (mut @controller.deviceId)}}
              />
              <DButton
                @icon="arrows-rotate"
                @action={{@controller.refreshDevices}}
                @disabled={{@controller.loading}}
                @title="discourse_kolide.onboarding.refresh_devices"
              />
            </div>
            <div class="instructions">
              {{htmlSafe
                (i18n
                  "discourse_kolide.onboarding.instructions"
                  topicLink=@controller.onboardingTopicLink
                  refreshIcon=(icon "arrows-rotate")
                )
              }}
            </div>
          </div>

          <div class="controls">
            <div class="inline-form">
              <label>
                <Input @type="checkbox" @checked={{@controller.mobileDevice}} />
                {{i18n "discourse_kolide.onboarding.kolide_not_available"}}
              </label>
            </div>
          </div>
        </div>

        <div class="control-group">
          <div class="controls inline-form">
            <DButton
              @action={{@controller.setKolideDevice}}
              @disabled={{@controller.loading}}
              @label="discourse_kolide.onboarding.save_device"
              type="submit"
              class="btn-primary"
            />

            <LinkTo
              @route="preferences.security"
              @model={{@controller.currentUser.username}}
              class="cancel"
            >
              {{i18n "cancel"}}
            </LinkTo>
          </div>
        </div>
      </ConditionalLoadingSpinner>
    </section>
  </template>
);
