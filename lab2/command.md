[https://chatgpt.com/share/0413d4b1-1967-4c24-8205-8372ae15c34e]

# Triển khai ứng dụng trên EKS với OIDC và ALB Ingress Controller có thể được chia thành nhiều phần. Dưới đây là hướng dẫn chi tiết về lý do cài đặt OIDC và cách triển khai một ứng dụng đơn giản trên EKS.

## Tại sao cần cài đặt OIDC

Lợi ích của OIDC:

- Quản lý quyền linh hoạt: OIDC (OpenID Connect) cho phép các dịch vụ trong Kubernetes sử dụng IAM roles của AWS một cách linh hoạt hơn. Điều này giúp quản lý quyền truy cập AWS resources cho các ứng dụng chạy trên EKS một cách chính xác và bảo mật hơn.

-Giảm rủi ro bảo mật: Thay vì sử dụng credentials cố định (long-term credentials) trong các ứng dụng, OIDC cho phép tạo các IAM roles với các quyền cụ thể và cấp chúng cho các dịch vụ dựa trên service accounts. Điều này giúp giảm thiểu rủi ro bảo mật.

- Tích hợp đơn giản hơn: OIDC giúp dễ dàng tích hợp với các dịch vụ khác mà không cần phải quản lý và phân phát các IAM keys thủ công.

- Quyền hạn tối thiểu: OIDC cho phép bạn chỉ định quyền tối thiểu cần thiết cho mỗi ứng dụng hay pod, tuân theo nguyên tắc quyền hạn tối thiểu.

==========================

## Để hiểu rõ hơn về lợi ích của việc sử dụng OIDC (OpenID Connect) trên EKS (Amazon Elastic Kubernetes Service), hãy xem xét một ví dụ cụ thể về cách OIDC giúp quản lý bảo mật và quyền truy cập mà không cần nhúng thông tin xác thực IAM (như access key và secret key) trực tiếp vào mã nguồn của bạn.

## Ví dụ về việc sử dụng OIDC trên EKS

### Trước khi sử dụng OIDC

Giả sử bạn có một ứng dụng chạy trong Kubernetes pod cần truy cập một dịch vụ AWS, chẳng hạn như S3 để lưu trữ và truy xuất tệp. Nếu không sử dụng OIDC, bạn có thể thực hiện điều này theo các bước sau:

- Tạo IAM User: Tạo một IAM user trên AWS với quyền truy cập vào S3.

- Lấy Access Key và Secret Key: Lấy access key và secret key từ IAM user.

- Nhúng thông tin xác thực vào mã nguồn:

* Bạn có thể nhúng trực tiếp access key và secret key vào mã nguồn hoặc một file cấu hình để ứng dụng sử dụng.
* Hoặc bạn có thể sử dụng chúng làm biến môi trường trong pod.

# Hạn chế của phương pháp này

- Bảo mật kém: Thông tin xác thực nhúng trong mã nguồn hoặc file cấu hình có nguy cơ bị lộ nếu mã nguồn được chia sẻ hoặc lưu trữ không an toàn.

- Quản lý phức tạp: Khi cần thay đổi quyền truy cập hoặc xoá tài khoản, bạn phải cập nhật thông tin trong mã nguồn hoặc cấu hình và tái triển khai ứng dụng.

Tính linh hoạt thấp: Khó khăn trong việc kiểm soát quyền truy cập cụ thể cho từng pod hay từng dịch vụ chạy trên Kubernetes.

## Trường hợp không sử dụng OIDC

Kịch bản
Giả sử bạn có một ứng dụng cần truy cập vào AWS S3 để lưu trữ và truy xuất tệp tin. Bạn sẽ phải quản lý thông tin xác thực IAM theo cách thủ công.

Các bước thực hiện mà không dùng OIDC

1. Tạo IAM User

- Truy cập AWS IAM console và tạo một IAM user với quyền truy cập vào S3.
- Tạo và lưu lại access key và secret key của IAM user này.

2. Nhúng thông tin xác thực trong Pod

- Bạn có thể nhúng access key và secret key vào mã nguồn hoặc cấu hình của ứng dụng.
- Dưới đây là một ví dụ sử dụng biến môi trường trong Kubernetes để lưu trữ thông tin xác thực:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: s3-access-pod
spec:
  containers:
    - name: my-container
      image: my-application-image
      env:
        - name: AWS_ACCESS_KEY_ID
          value: "<your-access-key>"
        - name: AWS_SECRET_ACCESS_KEY
          value: "<your-secret-key>"
      command: ["my-application"]
```

3. Cấu hình ứng dụng để sử dụng thông tin xác thực

Cấu hình ứng dụng của bạn để sử dụng các biến môi trường cho AWS SDK hoặc CLI

```python
import boto3
import os

s3 = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
)

response = s3.list_buckets()
print("Bucket List: %s" % response['Buckets'])

```

# Hạn chế của việc không sử dụng OIDC

1. Bảo mật kém:

- Rủi ro lộ thông tin: Thông tin xác thực được nhúng trực tiếp vào mã nguồn hoặc file cấu hình. Nếu mã nguồn bị rò rỉ, thông tin xác thực cũng bị lộ.
- Quản lý thông tin xác thực phức tạp: Mỗi lần cần thay đổi quyền truy cập hoặc thông tin xác thực, bạn phải cập nhật và triển khai lại ứng dụng.

2. Khả năng quản lý kém:

- Tính linh hoạt thấp: Không dễ dàng để thay đổi quyền truy cập cho từng pod hay ứng dụng mà không cần chỉnh sửa mã nguồn hoặc cấu hình.
- Khó khăn trong việc xoá bỏ quyền: Nếu một thông tin xác thực bị lộ, bạn phải thay đổi trên tất cả các pods sử dụng thông tin đó.

3. Không theo nguyên tắc quyền tối thiểu:

# Khó kiểm soát quyền: Mỗi pod có thể có quyền truy cập nhiều hơn mức cần thiết vì sử dụng cùng một thông tin xác thực cho nhiều pods.

## Sau khi sử dụng OIDC

Với OIDC, bạn có thể gán IAM roles trực tiếp cho các Kubernetes pods mà không cần nhúng thông tin xác thực vào mã nguồn:

- Tạo IAM Role: Tạo một IAM role với quyền truy cập S3 mong muốn.

- Tạo IAM Policy: Đính kèm IAM policy cần thiết vào IAM role này.

- Gán IAM Role cho Kubernetes Service Account:

* Tạo một service account trong Kubernetes và liên kết nó với IAM role thông qua OIDC provider.
* Cấu hình pod của bạn để sử dụng service account này.

- Ứng dụng truy cập AWS Services: Khi pod chạy, Kubernetes sẽ tự động cấp IAM role cho pod thông qua service account, cho phép ứng dụng truy cập vào S3 mà không cần access key và secret key.

# Không, bạn không cần phải tải AWS CLI hoặc chạy lệnh aws configure trong mỗi pod khi sử dụng OIDC trên EKS để tương tác với các dịch vụ AWS. Thay vào đó, với OIDC, bạn có thể gán IAM roles trực tiếp cho các pods thông qua Kubernetes service accounts mà không cần nhúng access key và secret key.

Cách OIDC hoạt động trên EKS

1. IAM Roles cho Service Accounts (IRSA):

- Tạo IAM Role: Bạn tạo một IAM role với các quyền cần thiết để truy cập tài nguyên AWS (ví dụ: S3, DynamoDB, v.v.).
- Gán Policy: Gán một IAM policy cho role này để chỉ định các quyền cụ thể.

2. OIDC Provider:

Thiết lập OIDC Provider: `Đảm bảo rằng cluster EKS của bạn có một OIDC provider. Điều này cho phép EKS sử dụng OIDC để cấp phát IAM roles cho pods.`

3. Tạo Kubernetes Service Account:

- Tạo Service Account: Tạo một Kubernetes service account trong namespace mà ứng dụng của bạn chạy.
- Liên kết với IAM Role: Sử dụng eksctl hoặc công cụ khác để liên kết service account này với IAM role mà bạn đã tạo.

4. Cấu hình Pod để sử dụng Service Account:

- Sử dụng Service Account trong Pod: Cấu hình file manifest của Kubernetes để sử dụng service account này cho pod hoặc deployment của bạn.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-service-account
  containers:
    - name: my-container
      image: my-image
      # Các cấu hình container khác
```

5. Truy cập AWS Services:

- SDK hoặc CLI trong Pod: Khi ứng dụng chạy trong pod và thực hiện các yêu cầu đến AWS services, IAM role liên kết với service account sẽ tự động được sử dụng để cấp quyền cho các yêu cầu này. Không cần phải nhập access key hoặc secret key.

# Lợi ích

- Bảo mật: Không cần nhúng thông tin xác thực AWS trong pod, giảm nguy cơ bảo mật.
- Quản lý dễ dàng: Thay đổi quyền truy cập bằng cách cập nhật IAM roles mà không cần thay đổi cấu hình pod.
- Tự động hóa: Các pods tự động nhận được quyền truy cập cần thiết thông qua IAM roles mà không cần sự can thiệp thủ công.

# Ví dụ

Giả sử bạn có một ứng dụng cần truy cập vào S3. Dưới đây là một ví dụ đơn giản:

Tạo IAM Role và Policy:

```bash
aws iam create-policy --policy-name MyS3AccessPolicy --policy-document file://s3-access-policy.json

eksctl create iamserviceaccount \
  --name my-service-account \
  --namespace default \
  --cluster my-cluster \
  --attach-policy-arn arn:aws:iam::<your-account-id>:policy/MyS3AccessPolicy \
  --approve

```

Trong đó, s3-access-policy.json chứa quyền cần thiết để truy cập vào S3.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: s3-access-pod
spec:
  serviceAccountName: my-service-account
  containers:
    - name: my-container
      image: my-application-image
      command: ["my-application"]
```

# Truy cập S3 trong ứng dụng:

Sử dụng AWS SDK (ví dụ: boto3 cho Python) để truy cập S3. IAM role sẽ tự động cấp quyền.

```yaml
import boto3

s3 = boto3.client('s3')
response = s3.list_buckets()
print("Bucket List: %s" % response['Buckets'])

```

================

# Nếu bạn không thiết lập OIDC (OpenID Connect) cho cluster EKS của mình và chỉ chạy các câu lệnh để tạo IAM policy và IAM service account như đã mô tả, `các pods trong Kubernetes sẽ không thể sử dụng IAM roles được liên kết với service account đó. Điều này xảy ra vì Kubernetes không có cách nào để sử dụng IAM roles mà không có OIDC provider được thiết lập.`

## Tác động của việc không sử dụng OIDC

1. IAM Service Account không hoạt động như mong đợi:

IAM Role không thể liên kết: Khi OIDC không được thiết lập, IAM roles không thể tự động gán cho các pods thông qua service accounts. Điều này có nghĩa là ngay cả khi bạn tạo một IAM role và IAM policy như trong ví dụ, pods của bạn sẽ không thể sử dụng IAM roles đó để truy cập vào các dịch vụ AWS. 2. Không có quyền truy cập AWS:

Truy cập bị từ chối: Ứng dụng trong pod sẽ không có quyền truy cập vào các dịch vụ AWS như S3, bởi vì nó không thể nhận được thông tin xác thực IAM cần thiết thông qua IAM roles. Nếu ứng dụng của bạn cố gắng truy cập S3 hoặc bất kỳ dịch vụ AWS nào khác, nó sẽ gặp lỗi truy cập bị từ chối.

3. Lợi ích của IAM Role bị mất:

- Bảo mật giảm: Bạn sẽ cần quay trở lại việc sử dụng access key và secret key bằng cách nhúng chúng vào mã nguồn hoặc cấu hình, điều này tăng nguy cơ bảo mật.
- Khó quản lý quyền: Bạn sẽ mất đi tính linh hoạt và khả năng quản lý quyền truy cập linh hoạt mà OIDC và IAM roles mang lại.

## Giải pháp

Nếu bạn muốn sử dụng IAM roles cho pods trong EKS, bạn cần đảm bảo rằng OIDC provider được thiết lập cho cluster. Dưới đây là các bước để đảm bảo thiết lập OIDC đúng cách:

Thiết lập OIDC cho cluster:

Kiểm tra OIDC Provider: Xác nhận rằng OIDC provider đã được thiết lập cho cluster bằng cách sử dụng lệnh eksctl hoặc AWS Management Console.

```yaml
eksctl utils associate-iam-oidc-provider --region <your-region> --cluster <your-cluster-name> --approve
```

## Kết luận

Việc không thiết lập OIDC cho cluster sẽ ngăn cản khả năng tự động sử dụng IAM roles thông qua Kubernetes service accounts, điều này làm giảm tính bảo mật và khó khăn trong quản lý quyền truy cập. Để tận dụng lợi ích đầy đủ của IAM roles, bạn cần thiết lập OIDC cho cluster EKS của mình.

======================

# Phần 1: Thiết lập OIDC cho EKS Cluster

## Câu lệnh 1: Xác định OIDC issuer ID cho cluster

```bash
cluster_name=devops-test-cluster
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo "OIDC Issuer ID: $oidc_id"

```

Mục đích: Xác định OIDC issuer ID cho cluster EKS của bạn. Issuer ID là một phần của URL được EKS cung cấp để xác định danh tính cho các dịch vụ trong cluster.
Chi tiết:

- aws eks describe-cluster --name $cluster_name: Lệnh này lấy thông tin chi tiết của cluster EKS có tên là devops-test-cluster.
- --query "cluster.identity.oidc.issuer": Truy xuất URL của issuer OIDC từ thông tin của cluster.
- --output text: Xuất kết quả dưới dạng văn bản.
- cut -d '/' -f 5: Chia URL theo dấu '/' và lấy phần thứ 5 (OIDC issuer ID).
- echo "OIDC Issuer ID: $oidc_id": In ra OIDC issuer ID để bạn biết giá trị của nó.

## Câu lệnh 2: Kiểm tra xem IAM OIDC provider đã tồn tại chưa

aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

```bash
provider_id=$(aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4)
if [ -z "$provider_id" ]; then
  echo "OIDC provider chưa tồn tại, tiến hành tạo mới."
  eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
else
  echo "OIDC provider đã tồn tại: $provider_id"
fi

```

Mục đích: Kiểm tra xem IAM OIDC provider với issuer ID đã tồn tại trong tài khoản AWS của bạn chưa.
Chi tiết:

- aws iam list-open-id-connect-providers: Liệt kê tất cả các OIDC provider trong tài khoản AWS.
- grep $oidc_id: Tìm kiếm OIDC provider có chứa issuer ID của cluster.
- cut -d "/" -f4: Chia chuỗi theo dấu '/' và lấy phần thứ 4 (ID của provider).
- if [ -z "$provider_id" ]: Kiểm tra nếu provider_id trống, nghĩa là provider chưa tồn tại.
- In thông báo về tình trạng tồn tại của provider và tạo mới nếu cần.

## Câu lệnh 3: Tạo IAM OIDC identity provider cho cluster

```bash
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
```

Mục đích: Tạo một IAM OIDC identity provider cho cluster EKS của bạn.
Chi tiết:

- eksctl utils associate-iam-oidc-provider: Lệnh này liên kết một OIDC provider với cluster EKS của bạn.
- --cluster $cluster_name: Xác định tên của cluster.
- --approve: Tự động phê duyệt mà không yêu cầu xác nhận tương tác từ người dùng.

# Phần 2: Cài đặt AWS Load Balancer Controller

## Bước 1: Tạo IAM Role với eksctl

Tải IAM policy cho AWS Load Balancer Controller

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

```

Tạo IAM policy

```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

```

Mục đích: Tạo một IAM policy trong tài khoản AWS dựa trên file JSON vừa tải.
Chi tiết:

- aws iam create-policy: Tạo một IAM policy mới.
- --policy-name AWSLoadBalancerControllerIAMPolicy: Đặt tên cho policy.
- --policy-document file://iam_policy.json: Chỉ định file JSON chứa định nghĩa policy.

# Tạo service account và gắn IAM policy

```bash
eksctl create iamserviceaccount \
  --cluster=$cluster_name \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

```

- --attach-policy-arn=arn:aws:iam::<your-account-id>:policy/AWSLoadBalancerControllerIAMPolicy: Gắn IAM policy với ARN đã tạo trước đó.
- --approve: Tự động phê duyệt mà không yêu cầu xác nhận từ người dùng

## Bước 2: Cài đặt AWS Load Balancer Controller

Thêm Helm repository của AWS

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

```

Mục đích: Thêm và cập nhật Helm repository chứa các biểu đồ Helm (charts) cho EKS.
Chi tiết:

- helm repo add eks https://aws.github.io/eks-charts: Thêm repository eks vào danh sách các repository Helm.
- helm repo update: Cập nhật danh sách các chart từ các repository đã thêm.

Cài đặt AWS Load Balancer Controller bằng Helm

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$cluster_name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

```

Chi tiết:

- helm install: Cài đặt một chart Helm.
- aws-load-balancer-controller: Đặt tên cho release Helm.
- eks/aws-load-balancer-controller: Xác định chart để cài đặt từ repository eks.
- -n kube-system: Đặt namespace cho cài đặt.
- --set clusterName=$cluster_name: Thiết lập tên cluster trong cấu hình chart.
- --set serviceAccount.create=false: Sử dụng service account đã tạo trước đó, không tạo mới.
- --set serviceAccount.name=aws-load-balancer-controller: Sử dụng service account có tên cụ thể.

# Phần 3: Triển khai ứng dụng mẫu (2048 game)

# Triển khai ứng dụng mẫu với ALB Ingress

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full.yaml
