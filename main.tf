module "my_instance_provision" {
  source = "../module"
  sgname = var.sgname
  machinetype = var.machinetype
  #mytags = var.mytags
  amiid = var.amiid
  keyname = var.keyname
 block1 = var.block1
  block2 = var.block2
  block3 = var.block3
  block4 = var.block4
  block5 = var.block5
  vpc_name = var.vpc_name
}
