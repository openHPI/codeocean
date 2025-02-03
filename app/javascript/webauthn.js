import {
  supported,
  create,
  get,
  parseCreationOptionsFromJSON,
  parseRequestOptionsFromJSON
} from "@github/webauthn-json/browser-ponyfill";

let form;
let credentialMethod;

function getPublicKey() {
  return { publicKey: form.data('publicKey') }
}

async function createCredential(publicKey) {
  const options = parseCreationOptionsFromJSON(publicKey);
  return await create(options);
}

async function getCredential(publicKey) {
  const options = parseRequestOptionsFromJSON(publicKey);
  return await get(options);
}

$(document).on('turbolinks:load', function() {
  if ($.isController('webauthn_credentials')) {
    form = $('form#new_webauthn_credential');
    credentialMethod = createCredential;
  } else if ($.isController('webauthn_credential_authentication')) {
    form = $('form#new_webauthn_credential_authentication');
    credentialMethod = getCredential;
  }

  if (!supported()) {
    setTimeout(() => {
      // In order to use `showPermanent`, we need to wait for the flash helper to finish initializing
      $.flash.danger({
        text: I18n.t('webauthn_credentials.browser_not_supported'),
        showPermanent: true,
        icon: ['fa-solid', 'fa-exclamation-triangle']
      });
    }, 100);
    form.find('input[type="submit"]').prop('disabled', true);
    return;
  }

  form.on('submit', function(event) {
    event.preventDefault();
    const publicKey = getPublicKey();
    credentialMethod(publicKey).then((credential) => {
        form.find('input[name="webauthn_credential[credential]"]').val(JSON.stringify(credential));
        this.submit();
      }
    ).catch((error) => {
      form.find('input[type="submit"]').prop('disabled', false);
      $.flash.danger({text: error});
    })
  });
});
