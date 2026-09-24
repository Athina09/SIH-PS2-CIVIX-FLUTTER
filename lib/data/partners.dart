// Ported 1:1 from src/data/partners.ts
import '../models/types.dart';

final List<IndustryPartner> partners = [
  IndustryPartner(
    id: 'tata-steel-foundation',
    name: 'Tata Steel Foundation',
    expertise: ['livelihood', 'water', 'health'],
    districtIds: ['west-singhbhum', 'saraikela-kharsawan', 'east-singhbhum'],
    offerTypes: ['funding', 'mentoring', 'testing'],
  ),
  IndustryPartner(
    id: 'ccl-csr',
    name: 'CCL CSR',
    expertise: ['water', 'infrastructure'],
    districtIds: ['ramgarh', 'hazaribagh', 'chatra'],
    offerTypes: ['funding', 'equipment'],
  ),
  IndustryPartner(
    id: 'bccl-csr',
    name: 'BCCL CSR',
    expertise: ['water quality', 'sanitation'],
    districtIds: ['dhanbad'],
    offerTypes: ['funding', 'testing'],
  ),
  IndustryPartner(
    id: 'sail-bokaro-csr',
    name: 'SAIL Bokaro CSR',
    expertise: ['infrastructure', 'environment'],
    districtIds: ['bokaro'],
    offerTypes: ['funding', 'manufacturing'],
  ),
  IndustryPartner(
    id: 'tata-motors-csr',
    name: 'Tata Motors CSR',
    expertise: ['skilling', 'manufacturing'],
    districtIds: ['east-singhbhum', 'saraikela-kharsawan'],
    offerTypes: ['funding', 'manufacturing', 'mentoring'],
  ),
  IndustryPartner(
    id: 'adityapur-msme',
    name: 'Adityapur MSME Cluster',
    expertise: ['fabrication', 'IoT hardware'],
    districtIds: ['saraikela-kharsawan', 'east-singhbhum'],
    offerTypes: ['manufacturing', 'equipment'],
  ),
  IndustryPartner(
    id: 'solar-epc-firm',
    name: 'Jharkhand Solar EPC Pvt Ltd',
    expertise: ['solar', 'irrigation', 'cold-storage'],
    districtIds: ['ranchi', 'gumla', 'palamu'],
    offerTypes: ['equipment', 'funding', 'testing'],
  ),
  IndustryPartner(
    id: 'state-ngo',
    name: 'Vikas Sahyog Samiti (NGO)',
    expertise: ['community mobilisation', 'livelihood'],
    districtIds: ['khunti', 'simdega', 'gumla', 'latehar'],
    offerTypes: ['mentoring', 'funding'],
  ),
];

IndustryPartner partnerById(String id) => partners.firstWhere((p) => p.id == id);
