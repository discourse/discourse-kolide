import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";

acceptance("Discourse Kolide Plugin", function (needs) {
  needs.user();
  needs.settings({ kolide_onboarding_topic_id: 1 });

  test("displays a notice to non-onboarded devices", async function (assert) {
    await visit("/");
    assert.ok(
      exists(".non-onboarded-device"),
      "notice is displayed to non-onboarded devices"
    );
  });
});

acceptance("Discourse Kolide Plugin - Mobile", function (needs) {
  needs.user();
  needs.mobileView();
  needs.settings({ kolide_onboarding_topic_id: 1 });

  test("hides the notice on mobile", async function (assert) {
    await visit("/");
    assert.notOk(
      exists(".non-onboarded-device"),
      "notice is not displayed on mobile"
    );
  });
});
