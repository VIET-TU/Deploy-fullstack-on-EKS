Có ALb được deplop như một deployment trong kube cluster có nhiệm vụ quản lý các rule, ta ALB ingress controller rồi, ta sẽ khai báo một ingress, ingress có nhiệm vụ nó sẽ tạo một ALB việc tạo ALB lúc này không phải tạo bằng tay như ví dụ ở bài kop, mà nó sẽ tự dộng quản lý bởi alb ingress controller, khi ta khai báo các ingress, và ingress đó khi ta thêm serive, bớt serivce thì nó tự dộng update lại lên ALB, ALB có hộ trợ mode instance khi đó traffic sẽ được load thẳng vô các con install thông qua Node port, hoặc thông qua mode IP, nó sẽ load thẳng vô IP của các POD tức là pod lúc sẽ được cấp thêm một second ip  để nhận traffic load từ ALB thông qua taget


#Triển khai một set ứng dụng đơn giản lên EKS
#YÊU CẦU: 
#  - Đã tạo thành công cluster ở lab1.
#  - Đã cài đặt eksctl, kubectl, aws cli, helm

#===Phần 1=========
#Follow guide sau để cài OIDC cho cluster:
https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

# Xác định OIDC issuer ID cho cluster của bạn.
cluster_name=devops-test-cluster
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

# Kiểm tra xem IAM OIDC provider đã tồn tại trong tài khoản AWS chưa.
#2. Determine whether an IAM OIDC provider with your cluster's issuer ID is already in your account.
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

# Tạo IAM OIDC identity provider cho cluster nếu chưa có.
#3. Create an IAM OIDC identity provider for your cluster with the following command.
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve


#Follow guide sau để cài đặt plugin ALB Ingress Controller
###************************ ALB Ingress Controller được triển khai như một deployment nằm trên node woker có nhiệm vụ quản lý các rule, Khi có một Yêu cầu tạo Ingress thì nó sẽ tự động tạo ALB trên amazon mà ta không phải tạo bằng như lab KOP*****************
https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

#Step 1: Create IAM Role using eksctl

## install with Helm

# Tải IAM policy cho AWS Load Balancer Controller
#Create an IAM policy.
## 1.Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf.
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json





# Tạo IAM policy
## 2.Create an IAM policy using the policy downloaded in the previous step.
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Tạo service account và gắn IAM policy
eksctl create iamserviceaccount \
  --cluster=devops-test-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::287925497349:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve


#Step 2: Install AWS Load Balancer Controller

#1. Add the eks-charts Helm chart repository. AWS maintains this repository on GitHub.

helm repo add eks https://aws.github.io/eks-charts

## 2 Update your local repo to make sure that you have the most recent charts.
helm repo update eks

## 3. Install the AWS Load Balancer Controller.
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=devops-test-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 



root@k8s-master-1:/tools/aws-cli# k get deployment -n kube-system
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           32s
coredns                        2/2     2            2           36m

root@k8s-master-1:/tools/aws-cli# k get pods -o wide -n kube-system
NAME                                           READY   STATUS    RESTARTS   AGE   IP               NODE                                               NOMINATED NODE   READINESS GATES
aws-load-balancer-controller-747c5d977-2r8wp   1/1     Running   0          81s   192.168.58.74    ip-192-168-52-46.ap-southeast-1.compute.internal   <none>           <none>
aws-load-balancer-controller-747c5d977-f7x9w   1/1     Running   0          81s   192.168.25.119   ip-192-168-2-74.ap-southeast-1.compute.internal    <none>

#Apply ứng dụng Sample (2048 game):
https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html#application-load-balancer-sample-application

#Kiểm tra ALB được tạo ra, truy cập thử Game-2048 thông qua DNS của ALB (lưu ý thêm http:// trước DNS)


=======> Việc deploy này hoàn toàn tự dộng do kubelet tự động quản lý, tự động cấu hình LoabBlancer, tagetgroup và trỏ vào trong các POD (Load thẳng vào POD luôn do type Target là IP)