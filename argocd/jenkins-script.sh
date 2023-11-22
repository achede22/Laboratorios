# Script para instalar ArgoCD y luego Jenkins dentro de ArgoCD

# Da un error si no eres root
whoami | grep root || echo "No eres root, te faltó el \"sudo\""


# Agregar el repositorio de bitnami a HELM
helm repo add bitnami https://github.com/bitnami/charts.git

# Actualizar los reporitorios 
helm repo update

# Instalar ArgoCD
helm install my-release oci://registry-1.docker.io/bitnamicharts/argo-cd

# copiar password de ArgoCD y respaldarla
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d tee argocd-passwd

# Hacer port-forward para poder tener acceso a ArgoCD desde Localhost
kubectl port-forward service/argo-cd-argocd-server -n argocd 8080:443 &

# Instalar "arcocd cli"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Guardar la contraseña de ArgoCD
export password=$(cat /ruta/al/archivo | awk 'NR==2')

# Loguearse en ArgoCD
argocd login 127.0.0.1:8080 --username admin --password $password
 
# Crear namespace "jenkins" en el cluster local de microk8s.
kubectl create ns jenkins

# Crear un Persistent Volume "PV" para Jenkins, de 1GB.
# el archivo está en argocd/jenkins-pv.yaml
mkdir -p /var/lib/microk8s-pv/jenkins

#parmisos totales al PATH jenkins, (sólo por tratarse de un laboratorio)
chmod 777 /var/lib/microk8s-pv/jenkins

# Crear el volumen persistente
kubectl apply -f jenkins-pv.yaml # no ncesita namespace

# Crear un Persistent Volume Claim "PVC" para Jenkins, de 1GB.
# el archivo está en argocd/jenkins-pvc.yaml
kubectl apply -f jenkins-pvc.yaml # el namespace está definido dentro del archivo

# Instalar JENKINS en ArgoCD
 argocd app create jenkins \
   --repo https://charts.bitnami.com/bitnami \
   --helm-chart jenkins \
   --dest-server https://kubernetes.default.svc \
   --dest-namespace jenkins \
   --values-literal-file jenkins_values.yaml \
   --upsert --revision 12.2.3

# La contraseña de jenkins está en el secret, que se puede revelar en LENS, o en el mismo ArgoCD.

# copiar password de JENKINS y respaldarla
kubectl -n jenkins get secret jenkins -o jsonpath="{.data.jenkins-password}" | base64 -d tee jenkins_password.txt
echo "Usuario: user"
cat jenkins_password.txt
