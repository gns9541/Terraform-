# VPC, Internet Gateway 리소스를 생성하고 Internet Gateway와 라우팅 되어 외부와 네트워크 연결이 가능한 Public Subnet 생성
# Private Subnet 내부에 있는 인스턴스들이 외부에서 들어오는 요청을 프록싱 해주는 Application Load Balancer,
# 내부에서 외부로만 네트워크 접근을 가능하게 해주는 NAT Gateway 를 Public Subnet 내부에 구성하고 Elastic IP를 부여

# ECS 클러스터를 위한 VPC 생성
resource "aws_vpc" "cluster_vpc" {
  tags = {
    Name = "ecs-vpc-${var.env_suffix}"
  }
  cidr_block = "10.30.0.0/16"
}

# 사용 가능한 가용 영역(AZ) 정보
data "aws_availability_zones" "available" {

}

# 프라이빗 서브넷 생성
# var.az_count만큼 생성되며, 각각 다른 AZ에 위치합니다.
# CIDR 블록은 VPC CIDR의 서브넷으로 자동 계산
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.cluster_vpc.id
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.cluster_vpc.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "ecs-private-subnet-${var.env_suffix}"
  }
}

# 퍼블릭 서브넷 생성
# 프라이빗 서브넷과 마찬가지로 var.az_count만큼 생성
# 퍼블릭 IP 자동 할당 활성화

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.cluster_vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.cluster_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-public-subnet-${var.env_suffix}"
  }
}
# VPC를 위한 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "cluster_igw" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = "ecs-igw-${var.env_suffix}"
  }
}

# 메인 라우트 테이블에 인터넷 게이트웨이로 가는 경로 추가
resource "aws_route" "internet_access" {
  route_table_id          = aws_vpc.cluster_vpc.main_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.cluster_igw.id
}

# 각 퍼블릭 서브넷에 NAT 게이트웨이를 생성 -> 프라이빗 서브넷의 아웃바운드 인터넷 접속을 위해 사용
resource "aws_eip" "nat_gateway" {
  count       = var.az_count
  vpc         = true
  depends_on  = [aws_internet_gateway.cluster_igw]
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.nat_gateway.*.id, count.index)

  tags = {
    Name = "NAT gw ${var.env_suffix}"
  }
}

# 퍼블릭 서브넷을 위한 라우트 테이블 생성 -> 모든 아웃바운드 트래픽을 인터넷 게이트웨이로 라우팅
resource "aws_route_table" "private_route" {
  count  = var.az_count
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }

  tags = {
    Name = "private-route-table-${var.env_suffix}"
  }
}

# 생성된 라우트 테이블을 각 서브넷과 연결
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_igw.id
  }

  tags = {
    Name = "ecs-route-table-${var.env_suffix}"
  }
}

resource "aws_route_table_association" "to-public" {
  count = length(aws_subnet.public)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public_route.*.id, count.index)
}

resource "aws_route_table_association" "to-private" {
  count = length(aws_subnet.private)
  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_route.*.id, count.index)
}
