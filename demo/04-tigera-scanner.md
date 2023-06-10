# 4 - Scan Images for Vulnerabilities with **tigera-scanner**

From now on we will work connected in the `control-plane` node. For convenience, I am assuming that all commands will be executed as `root`. To escalate your privilege, use:

```bash 
sudo su - root
```

Lets start by cloning a repository that contains two versions of a website and create the images from the Dockerfiles.

1. Clone the website repo.

   ```bash
   git clone https://github.com/regisftm/website.git && \
   cd website
   ```

   The directory structure of the website is as following:

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

2. Build the images for the version v1.0.0 and v1.1.0. The main difference in the Dockerfile is that they use different versions for the base images. 

   `v1.0.0/Dockerfile`
   <pre>
   FROM nginx:1.24.0-alpine

   COPY simple-website/ /usr/share/nginx/html/

   EXPOSE 80

   STOPSIGNAL SIGQUIT

   CMD ["nginx", "-g", "daemon off;"]
   </pre>

   `v1.1.0/Dockerfile`
   <pre>
   FROM nginx:1.25.0-alpine

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

   Verify that the images were built correctly.

   ```bash
   docker images
   ```

   You should see the following output:

   <pre>
   REPOSITORY   TAG                      IMAGE ID       CREATED             SIZE
   website      v1.1.0                   deee02ec4ab8   21 seconds ago      41.4MB
   website      v1.0.0                   2d1505fdb51b   20 seconds ago      41.1MB
   nginx        1.25.0-alpine            fe7edaf8a8dc   2 weeks ago         41.4MB
   nginx        1.24.0-alpine            1266a3a46e96   8 weeks ago         41.1MB
   </pre>

### Scan images using CLI

You can scan images manually or via CI/CD pipeline for vulnerabilities using the `tigera-scanner`.

Syntax:

<pre>
tigera-scanner scan [OPTIONS] \<image_name\>
</pre>

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

   Observe the differences between both results. Older images has more vulnerabilities than new images. 
   
   >**NOTE**: **Keep your images updated!**
   
Next, let's learn how to implement security policies for your applications.

---

[:arrow_right: 5 - Security Policies](/demo/05-security-policy.yaml) <br>

[:arrow_left: 3 - Install and Configure the Calico CNI](/demo/03-calico-installation.md)  
[:leftwards_arrow_with_hook: Back to Main](/README.md)  