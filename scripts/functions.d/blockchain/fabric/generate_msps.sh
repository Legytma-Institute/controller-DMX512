#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_cache_domain_msp.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../security/certificates/create_certificate_template.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../misc/create_provisioner.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_orderer_msp.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_peer_msp.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_admin_msp.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../security/certificates/assign_domain_admin_certificate.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate_user_msp.sh"

#
# Generate MSPs
#
function generate_msps() {
    # Generate cache domain MSP
    generate_cache_domain_msp ${LEGYTMA_DOMAIN} ${LEGYTMA_CA_FINGERPRINT} ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD}
    generate_cache_domain_msp ${AQUASLIDES_DOMAIN} ${AQUASLIDES_CA_FINGERPRINT} ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD}

    # Generate certificate templates
    create_certificate_template ${LEGYTMA_DOMAIN}
    create_certificate_template ${AQUASLIDES_DOMAIN}

    # Create provisioner
    create_provisioner ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} ${LEGYTMA_CA_ADMIN_SUBJECT} ${LEGYTMA_CA_ADMIN_PROVISIONER_NAME} ${LEGYTMA_CA_ADMIN_PROVISIONER_PASSWORD}

    # Generate MSPs
    generate_orderer_msp ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} ${ORDERER0_HOST}
    generate_orderer_msp ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} ${ORDERER1_HOST}
    # generate_orderer_msp ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} ${ORDERER2_HOST}
    generate_peer_msp ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} ${PEER0_HOST}
    generate_admin_msp ${LEGYTMA_CA_PROVISIONER_NAME} ${LEGYTMA_CA_PROVISIONER_PASSWORD} ${LEGYTMA_DOMAIN} "orderer"

    # Assign domain admin certificate
    assign_domain_admin_certificate ${LEGYTMA_DOMAIN} "orderer"

    # Create provisioner
    create_provisioner ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} ${AQUASLIDES_CA_ADMIN_SUBJECT} ${AQUASLIDES_CA_ADMIN_PROVISIONER_NAME} ${AQUASLIDES_CA_ADMIN_PROVISIONER_PASSWORD}

    # Generate MSPs
    generate_peer_msp ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} ${PEER0_HOST}
    generate_peer_msp ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} ${PEER1_HOST}
    generate_peer_msp ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} ${PEER2_HOST}
    generate_admin_msp ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} "peer"

    # Assign domain admin certificate
    assign_domain_admin_certificate ${AQUASLIDES_DOMAIN} "peer"

    # Generate user MSP
    generate_user_msp ${AQUASLIDES_CA_PROVISIONER_NAME} ${AQUASLIDES_CA_PROVISIONER_PASSWORD} ${AQUASLIDES_DOMAIN} "User1"
}

export -f generate_msps
