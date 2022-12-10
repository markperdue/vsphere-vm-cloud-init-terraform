from diagrams import Cluster, Diagram
from diagrams.generic.virtualization import Vmware
from diagrams.onprem.iac import Terraform

no_margin = {
    "margin": "-2"
}

margin = {
    "margin": "8"
}

with Diagram("", filename="virtual-machines", graph_attr=no_margin, show=False, direction="TB"):
    with Cluster(" ", graph_attr=margin):
        vm1 = Vmware("c1-cp1.lab")
    with Cluster("  ", graph_attr=margin):
        vm2 = Vmware("c1-node1.lab")
    with Cluster("   ", graph_attr=margin):
        vm3 = Vmware("c1-node2.lab")
    with Cluster("    ", graph_attr=margin):
        vm4 = Vmware("c1-node3.lab")

    terraform = Terraform()

    terraform >> vm1
    terraform >> vm2
    terraform >> vm3
    terraform >> vm4