#!/usr/bin/env python3
"""部署 studio 站点 SSL 证书到 CDN（delib.cloud.quanttide.com）。

证书来源：acme.sh 签发的泛域名证书（*.quanttide.com + delib.cloud.quanttide.com + quanttide.com，
ZeroSSL，90 天自动续期）。续期后需重跑本脚本把新证书绑定到 CDN 域名。

一次性配置（acme.sh 续期后自动执行）：
    acme.sh --install-cert -d '*.quanttide.com' \
      --reloadcmd "/path/to/venv/bin/python $(pwd)/deploy-studio-cert.py"

环境变量：
    ALIYUN_AK / ALIYUN_SK：阿里云 AccessKey（需 CDN 权限）
    ACME_CERT_DIR（可选）：acme.sh 证书目录，默认 ~/.acme.sh/*.quanttide.com_ecc/
依赖：
    pip install aliyun-python-sdk-core aliyun-python-sdk-cdn
"""

import os
import time

from aliyunsdkcore.client import AcsClient
from aliyunsdkcdn.request.v20180510.SetCdnDomainSSLCertificateRequest import (
    SetCdnDomainSSLCertificateRequest,
)

DOMAIN = "delib.cloud.quanttide.com"
CERT_DIR = os.environ.get(
    "ACME_CERT_DIR",
    os.path.expanduser("~/.acme.sh/*.quanttide.com_ecc/"),
)


def main() -> None:
    ak = os.environ["ALIYUN_AK"]
    sk = os.environ["ALIYUN_SK"]
    cert = open(os.path.join(CERT_DIR, "fullchain.cer")).read()
    key = open(os.path.join(CERT_DIR, "*.quanttide.com.key")).read()

    cli = AcsClient(ak, sk, "cn-hangzhou")
    req = SetCdnDomainSSLCertificateRequest()
    req.set_DomainName(DOMAIN)
    req.set_SSLProtocol("on")
    req.set_CertType("upload")
    # CertName 需唯一（CDN 不允许重名），用时间戳区分每次上传
    req.set_CertName(f"cert-{DOMAIN}-{int(time.time() * 1000)}")
    req.set_SSLPub(cert)
    req.set_SSLPri(key)
    resp = cli.do_action_with_exception(req)
    print(resp.decode())


if __name__ == "__main__":
    main()
