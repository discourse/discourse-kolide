import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";

acceptance("Discourse Kolide Plugin - Mobile", async function (needs) {
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
