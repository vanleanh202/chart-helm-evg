echo "Đang tạo Private Key..."
openssl genrsa -out dev.key 2048

# 3. Tạo file cấu hình tạm để sinh CSR (tránh lỗi thiếu openssl.cnf)
cat <<EOF > temp_openssl.cnf
[req]
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
CN = dev
O = ai-team
EOF

echo "Đang tạo CSR..."
openssl req -new -key dev.key -out dev.csr -config temp_openssl.cnf

# 4. Đẩy yêu cầu lên Kubernetes (Sử dụng openssl base64 để an toàn tuyệt đối)
export BASE64_CSR=$(openssl base64 -A -in dev.csr)

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dev-csr
spec:
  request: ${BASE64_CSR}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
  - client auth
EOF

# 5. Phê duyệt và lấy file .crt về
echo "Đang phê duyệt và lấy chứng chỉ..."
kubectl certificate approve dev-csr
kubectl get csr dev-csr -o jsonpath='{.status.certificate}' | openssl base64 -d -A > dev.crt

# 6. Tạo file Kubeconfig nhúng sẵn Base64 chuẩn
echo "Đang khởi tạo file dev-kubeconfig..."
export CLUSTER_CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
export CLUSTER_SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
export CLIENT_CRT=$(openssl base64 -A -in dev.crt)
export CLIENT_KEY=$(openssl base64 -A -in dev.key)

cat <<EOF > dev-kubeconfig
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
  name: kubernetes

users:
- name: dev
  user:
    client-certificate-data: ${CLIENT_CRT}
    client-key-data: ${CLIENT_KEY}

contexts:
- context:
    cluster: kubernetes
    namespace: support-ai
    user: dev
  name: support-ai-context

current-context: support-ai-context
EOF

echo "HOÀN TẤT! Đã tạo thành công file: dev-kubeconfig"