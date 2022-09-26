import {VariantDTO} from '@/types/VariantDTO';

export interface ProductDTO {
    id: string;
    title: string;
    handle: string;
    url: string;
    imageUrl: string;
    variants: Record<string, VariantDTO>;
}
