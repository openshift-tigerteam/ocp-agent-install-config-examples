rm -rf install
mkdir install
cp -r install-config.yaml agent-config.yaml openshift install
openshift-install agent create image --dir=install --log-level=debug