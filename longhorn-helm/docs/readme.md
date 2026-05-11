#Cai longhorn multipart

note: Thoi diem nay da cai 3 node worker. 2 node(27, 59) gan tag storage(u01/data-longhorn). 1 node(35) (/data/cold/data-longhorn) & (/data/hot/data-longhorn)

Day la cac buoc thuc hien cai node 35

Buoc 1:  gan Annotations

```bash
kubectl annotate node logs-cdn-vnpt-35 node.longhorn.io/default-disks-config='[

  {"path":"/data/hot/data-longhorn", "allowScheduling":true, "tags":["hot"]},

  {"path":"/data/cold/data-longhorn", "allowScheduling":true, "tags":["cold"]}

]'
```

Buoc 2: O day dang cho 1 node nen de replica 1. sau nay scale len

Tao 1 file storageClass.yaml

```bash
apiVersion: storage.k8s.io/v1

kind: StorageClass

metadata:

  name: longhorn-hot

provisioner: driver.longhorn.io

allowVolumeExpansion: true

reclaimPolicy: Retain

parameters:

  numberOfReplicas: "1" # QUAN TRỌNG: Phải để là 1

  staleReplicaTimeout: "2880"

  diskSelector: "hot" # Khớp với tag đã gán cho Worker 3

---

apiVersion: storage.k8s.io/v1

kind: StorageClass

metadata:

  name: longhorn-cold

provisioner: driver.longhorn.io

allowVolumeExpansion: true

reclaimPolicy: Retain

parameters:

  numberOfReplicas: "1" # QUAN TRỌNG: Phải để là 1

  staleReplicaTimeout: "2880"

  diskSelector: "cold" # Khớp với tag đã gán cho Worker 3
```

Buoc 3: Neu xin pvc thi phai gan dung storageClass name
