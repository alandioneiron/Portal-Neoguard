import { useState, type ReactElement } from 'react';
import { render } from '@testing-library/react';
// RouterProvider de 'react-router' (não 'react-router/dom'): no Vitest o subcaminho /dom carrega outra cópia
// do pacote (ESM x CJS) e quebra os contextos do roteador. Na aplicação (Vite) há uma cópia só.
import { createMemoryRouter, RouterProvider } from 'react-router';
import { Provedores } from '../Provedores';
import { rotas } from '../routes';
import { ModoProvider } from '../components/ficha/campos';

/** Renderiza um componente controlado guardando o valor num estado local. */
export function ComEstado<T>({
  inicial,
  children,
  readOnly,
  impressao,
}: {
  inicial: T;
  children: (valor: T, definir: (v: T) => void) => ReactElement;
  readOnly?: boolean;
  impressao?: boolean;
}) {
  const [valor, setValor] = useState<T>(inicial);
  return (
    <ModoProvider readOnly={readOnly} impressao={impressao}>
      {children(valor, setValor)}
    </ModoProvider>
  );
}

/** Renderiza o portal inteiro (rotas reais) numa rota inicial, com tema, antd App e identidade. */
export function renderRota(caminho: string) {
  const roteador = createMemoryRouter(rotas, { initialEntries: [caminho] });
  const r = render(
    <Provedores semAnimacao>
      <RouterProvider router={roteador} />
    </Provedores>,
  );
  return { ...r, roteador };
}

export const AUTOR_TESTE = { nome: 'Pessoa Teste', email: 'teste@exemplo.invalid' };

export function salvarAutorNoNavegador() {
  window.localStorage.setItem('portal.autor', JSON.stringify(AUTOR_TESTE));
}
