import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import topicFixtures from "discourse/tests/fixtures/topic";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { cloneJSON } from "discourse-common/lib/object";

function topicWithKolideButton(topicId) {
  const topic = cloneJSON(topicFixtures[`/t/${topicId}.json`]);
  topic.archetype = "private_message";
  topic.post_stream.posts[0].cooked = `<a class="kolide-recheck" href="#" data-issue="42403">recheck</a>`;
  return topic;
}

acceptance("Discourse Kolide Plugin", async function (needs) {
  needs.user();
  const topicId = 130;

  test("recheck button", async function (assert) {
    pretender.get(`/t/${topicId}.json`, () => {
      return response(topicWithKolideButton(topicId));
    });
    pretender.post("/kolide/issues/42403/recheck.json", () => {
      return response({
        success: "OK",
      });
    });

    await visit(`/t/lorem-ipsum-dolor-sit-amet/${topicId}`);
    assert.ok(exists(".kolide-recheck"), "Recheck button exists");
    await click(".kolide-recheck");

    assert.strictEqual(
      query(".dialog-content .dialog-body p").innerHTML.trim(),
      "Issue recheck is initiated.",
      "Displays dialog with success message"
    );
  });
});

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
