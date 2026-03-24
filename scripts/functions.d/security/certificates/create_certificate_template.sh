#!/usr/bin/env bash

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../logging/stdout/info.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../files/generate/create_data_file.sh"

#
# Create certificate template for a given domain
#
function create_certificate_template() {
    local DOMAIN
    local TEMPLATE_PATH
    local TEMPLATE_FILE

    DOMAIN=$1

    TEMPLATE_PATH="${TEMPLATES_DIR}/${DOMAIN}"
    TEMPLATE_FILE="${TEMPLATE_PATH}/certificate.tpl"

    if [ ! -f "${TEMPLATE_FILE}" ]; then
        info "Creating template ${TEMPLATE_FILE}"

        mkdir -p "${TEMPLATE_PATH}"

        cat > "${TEMPLATE_FILE}" << EOF
{
  "subject": {
    {{- if .Subject.Country }}
        "country": {{ toJson .Subject.Country }},
    {{- else }}
        "country": {{ toJson .Insecure.User.country }},
    {{- end }}
    {{- if .Subject.Province }}
        "province": {{ toJson .Subject.Province }},
    {{- else }}
        "province": {{ toJson .Insecure.User.province }},
    {{- end }}
    {{- if .Subject.Locality }}
        "locality": {{ toJson .Subject.Locality }},
    {{- else }}
        "locality": {{ toJson .Insecure.User.locality }},
    {{- end }}
    {{- if .Subject.StreetAddress }}
        "streetAddress": {{ toJson .Subject.StreetAddress }},
    {{- else }}
        "streetAddress": {{ toJson .Insecure.User.streetAddress }},
    {{- end }}
    {{- if .Subject.PostalCode }}
        "postalCode": {{ toJson .Subject.PostalCode }},
    {{- else }}
        "postalCode": {{ toJson .Insecure.User.postalCode }},
    {{- end }}
    {{- if .Subject.CommonName }}
        "commonName": {{ toJson .Subject.CommonName }},
    {{- else }}
        "commonName": {{ toJson .Insecure.User.commonName }},
    {{- end }}
    {{- if .Subject.Organization }}
        "organization": {{ toJson .Subject.Organization }},
    {{- else }}
        "organization": {{ toJson .Insecure.User.organization }},
    {{- end }}
    {{- if .Subject.OrganizationalUnit }}
        "organizationalUnit": {{ toJson .Subject.OrganizationalUnit }}
    {{- else }}
        "organizationalUnit": {{ toJson .Insecure.User.organizationalUnit }}
    {{- end }}
  },
  "sans": {{ toJson .SANs }},
  {{- if .KeyUsage }}
    "keyUsage": {{ toJson .KeyUsage }},
  {{- else if .Insecure.User.keyUsage }}
    "keyUsage": {{ toJson .Insecure.User.keyUsage }},
  {{- else }}
    "keyUsage": ["digitalSignature"],
  {{- end }}
  {{- if .Principals }}
    "principals": {{ toJson .Principals }},
  {{- else if .Insecure.User.principals }}
    "principals": {{ toJson .Insecure.User.principals }},
  {{- end }}
  "crlDistributionPoints": [
    "http://ca.docker.vpn.${DOMAIN}/1.0/crl"
  ],
{{- if .ExtKeyUsage }}
  "extKeyUsage": {{ toJson .ExtKeyUsage }},
{{- else if .Insecure.User.extKeyUsage }}
  "extKeyUsage": {{ toJson .Insecure.User.extKeyUsage }},
{{- end }}
  "basicConstraints": {
    {{- if .BasicConstraints.IsCA }}
      "isCA": {{ toJson .BasicConstraints.IsCA }},
    {{- else if .Insecure.User.isCA }}
      "isCA": {{ toJson .Insecure.User.isCA }},
    {{- else }}
      "isCA": false,
    {{- end }}
    {{- if .BasicConstraints.MaxPathLen }}
      "maxPathLen": {{ toJson .BasicConstraints.MaxPathLen }}
    {{- else if .Insecure.User.maxPathLen }}
      "maxPathLen": {{ toJson .Insecure.User.maxPathLen }}
    {{- else }}
      "maxPathLen": 0
    {{- end }}
  }
}
EOF
#   {{- if .NotBefore }}
#     "notBefore": {{ toJson .NotBefore }},
#   {{- else if .Insecure.User.notBefore }}
#     "notBefore": {{ toJson .Insecure.User.notBefore }},
#   {{- else }}
#     "notBefore": "0s",
#   {{- end }}
#   {{- if .NotAfter }}
#     "notAfter": {{ toJson .NotAfter }}
#   {{- else if .Insecure.User.notAfter }}
#     "notAfter": {{ toJson .Insecure.User.notAfter }}
#   {{- else }}
#     "notAfter": "10y"
#   {{- end }}
    fi

    create_data_file "${DOMAIN}" "sign.orderer" '"Orderer"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.peer" '"Peer"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.user" '"Client"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "sign.admin" '"Admin"' '["digitalSignature"]'
    create_data_file "${DOMAIN}" "tls.server" '"Server"' '["digitalSignature", "keyEncipherment"]' '["serverAuth", "clientAuth"]'
    create_data_file "${DOMAIN}" "tls.client" '"Admin"' '["digitalSignature", "keyEncipherment"]' '["serverAuth", "clientAuth"]'
}

export -f create_certificate_template
