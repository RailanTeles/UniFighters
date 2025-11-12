shader_type canvas_item;

// Este é o único valor que você mexe
// É quantos pixels a barra vai inclinar para a direita
uniform float inclinacao_em_pixels = 30.0;

void vertex() {
	// Inclina a coordenada X baseado em UV.y
	// UV.y vai de 0.0 (topo) até 1.0 (base)
	VERTEX.x += UV.y * inclinacao_em_pixels;
}