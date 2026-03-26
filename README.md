# 🚀 AWS DevOps CI/CD Pipeline

This project demonstrates a production-style DevOps pipeline using AWS, Terraform, Docker, and GitHub Actions.

It automates infrastructure provisioning and application deployment using CI/CD principles.

---

## 🧩 Architecture

```
Developer → GitHub → GitHub Actions → EC2 → Docker → Application
                          ↓
                       AWS ALB
```

---

## ⚙️ Tech Stack

* **Cloud** : AWS (EC2, ALB, VPC)
* **Infrastructure as Code** : Terraform
* **Containerization** : Docker
* **CI/CD** : GitHub Actions
* **Web Server** : Apache (httpd)

---

## 🚀 Features

* Infrastructure provisioning using Terraform
* Multi-AZ deployment using AWS VPC and subnets
* Application Load Balancer for traffic distribution
* Containerized application deployment using Docker
* Automated CI/CD pipeline using GitHub Actions
* SSH-based remote deployment to EC2 instances

---

## 📁 Project Structure

```
aws-devops-ci-cd-pipeline/
│
├── app/
│   ├── Dockerfile
│   └── index.html
│
├── infra/
│   ├── main.tf
│   └── provider.tf
│
├── .github/workflows/
│   └── deploy.yml
│
├── .gitignore
└── README.md
```

---

## 🔄 CI/CD Workflow

1. Developer pushes code to GitHub
2. GitHub Actions pipeline is triggered
3. Workflow connects to EC2 using SSH
4. Existing container is stopped and removed
5. New Docker image is built
6. Container is deployed with updated version

---

## 🌐 Deployment

After deployment, the application is accessible via:

```
http://<ALB-DNS>
```

Refresh the page to observe responses from different instances.

---

## 🧪 How to Test

1. Modify content in `app/index.html`
2. Push changes to GitHub:

```
git add .
git commit -m "update app"
git push
```

3. GitHub Actions will automatically deploy changes
4. Open ALB DNS and verify updates

---

## 🔐 Security Note

* SSH private key is stored securely in GitHub Secrets
* For production systems, IAM roles and secure access methods are recommended

---

## 📌 Future Improvements

* Use AWS ECR for Docker image storage
* Implement rolling or canary deployments
* Add monitoring using CloudWatch
* Replace SSH with SSM or IAM-based access

---

## 👨‍💻 Author

Akshay Anand
