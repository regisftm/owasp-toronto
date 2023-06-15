# 4 - Scan Images for Vulnerabilities with **tigera-scanner**

From this point forward, we will work directly on the control-plane node. Assume that all commands execute as the `root` user. If you didn't yet, elevate your privileges using the following command:

```bash 
sudo su - root
```

Let's start by cloning a repository containing two website versions and creating the images from the Dockerfiles.

1. Clone the website repo.

   ```bash
   git clone https://github.com/regisftm/website.git && \
   cd website
   ```

   The directory structure of the website is as follows:

   <pre>
   .
   ├── README.md
   ├── v1.0.0
   │   ├── Dockerfile
   │   └── simple-website
   └── v1.1.0
       ├── Dockerfile
       └── simple-website
   </pre>

2. Build the images for the versions v1.0.0 and v1.1.0. The main difference in the Dockerfile is that they use different versions for the base images. 

   `v1.0.0/Dockerfile`
   <pre>
   FROM nginx:1.23.3-alpine

   COPY simple-website/ /usr/share/nginx/html/

   EXPOSE 80

   STOPSIGNAL SIGQUIT

   CMD ["nginx", "-g", "daemon off;"]
   </pre>

   `v1.1.0/Dockerfile`
   <pre>
   FROM nginx:1.25.1-alpine

   COPY simple-website/ /usr/share/nginx/html/

   EXPOSE 80

   STOPSIGNAL SIGQUIT

   CMD ["nginx", "-g", "daemon off;"]
   </pre>

   Build the images with the following commands:

   ```bash
   docker build -t website:v1.0.0 v1.0.0/.
   docker build -t website:v1.1.0 v1.1.0/.
   ```

   Verify the correct build of the images.

   ```bash
   docker images
   ```

   You should see the following output:

   <pre>
   REPOSITORY   TAG             IMAGE ID       CREATED          SIZE
   website      v1.1.0          96b111ed81cb   5 seconds ago    44.8MB
   website      v1.0.0          6a395cb93af9   8 seconds ago    44.1MB
   nginx        1.25.1-alpine   4937520ae206   31 minutes ago   41.4MB
   nginx        1.23.3-alpine   2bc7edbc3cf2   4 months ago     40.7MB
   </pre>

### Scan images using CLI

You can scan images manually or via CI/CD pipeline for vulnerabilities using the `tigera-scanner`.

Syntax:

```console
tigera-scanner scan [OPTIONS] <image_name>
```

Options:

- `--apiurl` - Calico Cloud API URL path. You can get this URL in Manager UI, Image Assurance, Scan settings.
- `--token` - secure API or authorization token to make requests to Calico Cloud API URL. You can get this URL in Manager UI, Image Assurance, Scan settings.
- `--warn_threshold` - CVSS threshold for Warn scan results. Range from 0.0 - 10.0.
- `--fail_threshold` - CVSS threshold for Fail scan results. Range from 0.0 - 10.0.
- `--vulnerability_db_path` - path to a folder to store vulnerability data (defaults to $XDG_CACHE_HOME; if it is not set, defaults to $HOME/.cache).
- `--input_file` \<file-path\> - Path to a JSON file containing image URLs.
- `--output_file` \<file-path\> - File path that will contain scan results in a JSON format.

1. Scan the images that we built for vulnerabilities.

   ```bash
   tigera-scanner scan website:v1.0.0
   ```

   ```bash
   tigera-scanner scan website:v1.1.0
   ```

   Observe the differences between both results. **Older images have more vulnerabilities than new images.**  
   
> **Note**: **Keep your base images updated!**
   
Next, let's learn how to implement security policies for your applications.

---

[:arrow_right: 5 - Protect Your Application with **Security Policies**](/demo/05-security-policy.md) <br>

[:arrow_left: 3 - Install and Configure the Calico CNI](/demo/03-calico-installation.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)  
